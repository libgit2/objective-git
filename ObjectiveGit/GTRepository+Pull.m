//
//  GTRepository+Pull.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/17/15.
//  Copyright © 2015 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Pull.h"

#import "GTCommit.h"
#import "GTIndex.h"
#import "GTOID.h"
#import "GTRemote.h"
#import "GTReference.h"
#import "GTRepository+Committing.h"
#import "GTRepository+RemoteOperations.h"
#import "GTTree.h"
#import "NSError+Git.h"
#import "git2/errors.h"

@implementation GTRepository (Pull)

#pragma mark - Pull

- (BOOL)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemoteFetchTransferProgressBlock)progressBlock
{
	NSParameterAssert(branch);
	NSParameterAssert(remote);

	GTRepository *repo = branch.repository;

	if (![self fetchRemote:remote withOptions:options error:error progress:progressBlock]) {
		return NO;
	}

	// Get tracking branch after fetch so that it is up-to-date and doesn't need to be refreshed from disk
	GTBranch *trackingBranch;
	if (branch.branchType == GTBranchTypeLocal) {
		BOOL success = NO;
		trackingBranch = [branch trackingBranchWithError:error success:&success];
		if (!success) {
			if (error != NULL) *error = [NSError git_errorFor:GIT_ERROR description:@"Tracking branch not found for %@", branch.name];
			return NO;
		}
		else if (!trackingBranch) {
			// Error should already be provided by libgit2
			return NO;
		}
	}
	else {
		// When given a remote branch, use it as the tracking branch
		trackingBranch = branch;
	}

	// Check if merge is necessary
	GTBranch *localBranch = [repo currentBranchWithError:error];
	if (!localBranch) {
		return NO;
	}

	GTCommit *localCommit = [localBranch targetCommitWithError:error];
	if (!localCommit) {
		return NO;
	}

	GTCommit *remoteCommit = [trackingBranch targetCommitWithError:error];
	if (!remoteCommit) {
		return NO;
	}

	if ([localCommit.SHA isEqualToString:remoteCommit.SHA]) {
		// Local and remote tracking branch are already in sync
		return YES;
	}

	GTMergeAnalysis analysis = GTMergeAnalysisNone;
	BOOL success = [self analyseMerge:&analysis fromBranch:trackingBranch error:error];
	if (!success) {
		return NO;
	}

	if (analysis & GTMergeAnalysisUpToDate) {
		// Nothing to do
		return YES;
	} else if (analysis & GTMergeAnalysisFastForward ||
			   analysis & GTMergeAnalysisUnborn) {
		// Fast-forward branch
		NSString *message = [NSString stringWithFormat:@"merge %@/%@: Fast-forward", remote.name, trackingBranch.name];
		GTReference *reference = [localBranch.reference referenceByUpdatingTarget:remoteCommit.SHA message:message error:error];
		BOOL checkoutSuccess = [self checkoutReference:reference strategy:GTCheckoutStrategyForce error:error progressBlock:nil];

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
			if (error != NULL) *error = [NSError git_errorFor:GIT_ECONFLICT description:@"Merge conflict, pull aborted"];
			return NO;
		}

		GTTree *newTree = [index writeTreeToRepository:repo error:error];
		if (!newTree) {
			return NO;
		}

		// Create merge commit
		NSString *message = [NSString stringWithFormat:@"Merge branch '%@'", localBranch.shortName];
		NSArray *parents = @[ localCommit, remoteCommit ];

		// FIXME: This is stepping on the local tree
		GTCommit *mergeCommit = [repo createCommitWithTree:newTree  message:message parents:parents updatingReferenceNamed:localBranch.name error:error];
		if (!mergeCommit) {
			return NO;
		}

		BOOL success = [self checkoutReference:localBranch.reference strategy:GTCheckoutStrategyForce error:error progressBlock:nil];
		return success;
	}

	return NO;
}

- (BOOL)analyseMerge:(GTMergeAnalysis *)analysis fromBranch:(GTBranch *)fromBranch error:(NSError **)error
{
	NSParameterAssert(analysis != NULL);
	NSParameterAssert(fromBranch != nil);

	GTCommit *fromCommit = [fromBranch targetCommitWithError:error];
	if (!fromCommit) {
		return NO;
	}

	git_annotated_commit *annotatedCommit;

	int gitError = git_annotated_commit_lookup(&annotatedCommit, self.git_repository, fromCommit.OID.git_oid);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to lookup annotated comit for %@", fromCommit];
		return NO;
	}

	// Allow fast-forward or normal merge
	git_merge_preference_t preference = GIT_MERGE_PREFERENCE_NONE;

	// Merge analysis
	gitError = git_merge_analysis((git_merge_analysis_t *)analysis, &preference, self.git_repository, (const git_annotated_commit **) &annotatedCommit, 1);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to analyze merge"];
		return NO;
	}

	// Cleanup
	git_annotated_commit_free(annotatedCommit);

	return YES;
}

@end
