//
//  GTRepository+Merging.m
//  ObjectiveGitFramework
//
//  Created by Piet Brauer on 02/03/16.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Merging.h"
#import "GTOID.h"
#import "NSError+Git.h"
#import "git2/errors.h"
#import "GTCommit.h"
#import "GTReference.h"
#import "GTRepository+Committing.h"
#import "GTRepository+Pull.h"
#import "GTTree.h"
#import "GTIndex.h"
#import "GTIndexEntry.h"

typedef void (^GTRemoteFetchTransferProgressBlock)(const git_transfer_progress *stats, BOOL *stop);

@implementation GTRepository (Merging)

typedef void (^GTRepositoryEnumerateMergeHeadEntryBlock)(GTOID *entry, BOOL *stop);

typedef struct {
	__unsafe_unretained GTRepositoryEnumerateMergeHeadEntryBlock enumerationBlock;
} GTEnumerateMergeHeadEntriesPayload;

int GTMergeHeadEntriesCallback(const git_oid *oid, void *payload) {
	GTEnumerateMergeHeadEntriesPayload *entriesPayload = payload;

	GTRepositoryEnumerateMergeHeadEntryBlock enumerationBlock = entriesPayload->enumerationBlock;

	GTOID *gtoid = [GTOID oidWithGitOid:oid];

	BOOL stop = NO;

	enumerationBlock(gtoid, &stop);

	return (stop == YES ? GIT_EUSER : 0);
}

- (BOOL)enumerateMergeHeadEntriesWithError:(NSError **)error usingBlock:(void (^)(GTOID *mergeHeadEntry, BOOL *stop))block {
	NSParameterAssert(block != nil);

	GTEnumerateMergeHeadEntriesPayload payload = {
		.enumerationBlock = block,
	};

	int gitError = git_repository_mergehead_foreach(self.git_repository, GTMergeHeadEntriesCallback, &payload);

	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get mergehead entries"];
		return NO;
	}

	return YES;
}

- (NSArray *)mergeHeadEntriesWithError:(NSError **)error {
	NSMutableArray *entries = [NSMutableArray array];

	[self enumerateMergeHeadEntriesWithError:error usingBlock:^(GTOID *mergeHeadEntry, BOOL *stop) {
		[entries addObject:mergeHeadEntry];

		*stop = NO;
	}];

	return entries;
}

- (BOOL)mergeBranchIntoCurrentBranch:(GTBranch *)branch withError:(NSError **)error {
	// Check if merge is necessary
	GTBranch *localBranch = [self currentBranchWithError:error];
	if (!localBranch) {
		return NO;
	}

	GTCommit *localCommit = [localBranch targetCommitWithError:error];
	if (!localCommit) {
		return NO;
	}

	GTCommit *remoteCommit = [branch targetCommitWithError:error];
	if (!remoteCommit) {
		return NO;
	}

	if ([localCommit.SHA isEqualToString:remoteCommit.SHA]) {
		// Local and remote tracking branch are already in sync
		return YES;
	}

	GTMergeAnalysis analysis = GTMergeAnalysisNone;
	BOOL success = [self analyzeMerge:&analysis fromBranch:branch error:error];
	if (!success) {
		return NO;
	}

	if (analysis & GTMergeAnalysisUpToDate) {
		// Nothing to do
		return YES;
	} else if (analysis & GTMergeAnalysisFastForward ||
			   analysis & GTMergeAnalysisUnborn) {
		// Fast-forward branch
		NSString *message = [NSString stringWithFormat:@"merge %@: Fast-forward", branch.name];
		GTReference *reference = [localBranch.reference referenceByUpdatingTarget:remoteCommit.SHA message:message error:error];
		BOOL checkoutSuccess = [self checkoutReference:reference options:[GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategyForce] error:error];
		return checkoutSuccess;
	} else if (analysis & GTMergeAnalysisNormal) {
		// Do normal merge
		GTTree *localTree = localCommit.tree;
		GTTree *remoteTree = remoteCommit.tree;

		// TODO: Find common ancestor
		GTTree *ancestorTree = nil;

		// Merge
		GTIndex *index = [localTree merge:remoteTree ancestor:ancestorTree error:error];
		if (!index) {
			return NO;
		}

		// Check for conflict
		if (index.hasConflicts) {
			NSMutableArray <NSString *>*files = [NSMutableArray array];
			[index enumerateConflictedFilesWithError:error usingBlock:^(GTIndexEntry * _Nonnull ancestor, GTIndexEntry * _Nonnull ours, GTIndexEntry * _Nonnull theirs, BOOL * _Nonnull stop) {
				[files addObject:ours.path];
			}];

			if (error != NULL) {
				NSDictionary *userInfo = @{GTPullMergeConflictedFiles: files};
				*error = [NSError git_errorFor:GIT_ECONFLICT description:@"Merge conflict" userInfo:userInfo failureReason:nil];
			}

			// Write conflicts
			git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;
			git_checkout_options checkout_opts = GIT_CHECKOUT_OPTIONS_INIT;
			checkout_opts.checkout_strategy = (GIT_CHECKOUT_SAFE | GIT_CHECKOUT_ALLOW_CONFLICTS);

			git_annotated_commit *annotatedCommit;
			[self annotatedCommit:&annotatedCommit fromCommit:remoteCommit error:error];

			git_merge(self.git_repository, (const git_annotated_commit **)&annotatedCommit, 1, &merge_opts, &checkout_opts);

			return NO;
		}

		GTTree *newTree = [index writeTreeToRepository:self error:error];
		if (!newTree) {
			return NO;
		}

		// Create merge commit
		NSString *message = [NSString stringWithFormat:@"Merge branch '%@'", localBranch.shortName];
		NSArray *parents = @[ localCommit, remoteCommit ];

		// FIXME: This is stepping on the local tree
		GTCommit *mergeCommit = [self createCommitWithTree:newTree  message:message parents:parents updatingReferenceNamed:localBranch.name error:error];
		if (!mergeCommit) {
			return NO;
		}

		BOOL success = [self checkoutReference:localBranch.reference options:[GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategyForce] error:error];
		return success;
	}

	return NO;
}

- (BOOL)annotatedCommit:(git_annotated_commit **)annotatedCommit fromCommit:(GTCommit *)fromCommit error:(NSError **)error {
	int gitError = git_annotated_commit_lookup(annotatedCommit, self.git_repository, fromCommit.OID.git_oid);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to lookup annotated commit for %@", fromCommit];
		return NO;
	}

	return YES;
}

- (BOOL)analyzeMerge:(GTMergeAnalysis *)analysis fromBranch:(GTBranch *)fromBranch error:(NSError **)error {
	NSParameterAssert(analysis != NULL);
	NSParameterAssert(fromBranch != nil);

	GTCommit *fromCommit = [fromBranch targetCommitWithError:error];
	if (!fromCommit) {
		return NO;
	}

	git_annotated_commit *annotatedCommit;
	[self annotatedCommit:&annotatedCommit fromCommit:fromCommit error:error];

	// Allow fast-forward or normal merge
	git_merge_preference_t preference = GIT_MERGE_PREFERENCE_NONE;

	// Merge analysis
	int gitError = git_merge_analysis((git_merge_analysis_t *)analysis, &preference, self.git_repository, (const git_annotated_commit **) &annotatedCommit, 1);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to analyze merge"];
		return NO;
	}

	// Cleanup
	git_annotated_commit_free(annotatedCommit);

	return YES;
}

@end
