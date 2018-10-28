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
#import "GTOdbObject.h"
#import "GTObjectDatabase.h"
#import "GTAnnotatedCommit.h"
#import "EXTScope.h"

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

- (BOOL)analyzeMerge:(GTMergeAnalysis *)analysis preference:(GTMergePreference *)preference fromAnnotatedCommits:(NSArray <GTAnnotatedCommit *> *)annotatedCommits error:(NSError * _Nullable __autoreleasing *)error {
	NSParameterAssert(annotatedCommits != nil);

	const git_annotated_commit **annotatedHeads = NULL;
	if (annotatedCommits.count > 0) {
		annotatedHeads = calloc(annotatedCommits.count, sizeof(git_annotated_commit *));
		for (NSUInteger i = 0; i < annotatedCommits.count; i++){
			annotatedHeads[i] = [annotatedCommits[i] git_annotated_commit];
		}
	}
	@onExit {
		free(annotatedHeads);
	};

	git_merge_analysis_t merge_analysis;
	git_merge_preference_t merge_preference;
	int gitError = git_merge_analysis(&merge_analysis, &merge_preference, self.git_repository, annotatedHeads, annotatedCommits.count);
	if (gitError != 0) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to analyze merge"];
		return NO;
	}

	*analysis = (GTMergeAnalysis)merge_analysis;
	if (preference != NULL) *preference = (GTMergePreference)merge_preference;

	return YES;
}

- (BOOL)mergeAnnotatedCommits:(NSArray <GTAnnotatedCommit *> *)annotatedCommits mergeOptions:(NSDictionary *)mergeOptions checkoutOptions:(GTCheckoutOptions *)checkoutOptions error:(NSError **)error {
	NSParameterAssert(annotatedCommits);

	git_merge_options merge_opts = GIT_MERGE_OPTIONS_INIT;

	const git_annotated_commit **annotated_commits = NULL;
	if (annotatedCommits.count > 0) {
		annotated_commits = calloc(annotatedCommits.count, sizeof(git_annotated_commit *));
		for (NSUInteger i = 0; i < annotatedCommits.count; i++){
			annotated_commits[i] = [annotatedCommits[i] git_annotated_commit];
		}
	}
	@onExit {
		free(annotated_commits);
	};

	int gitError = git_merge(self.git_repository, annotated_commits, annotatedCommits.count, &merge_opts, checkoutOptions.git_checkoutOptions);
	if (gitError != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Merge failed"];
		}
		return NO;
	}
	return YES;
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

	GTAnnotatedCommit *remoteAnnotatedCommit = [GTAnnotatedCommit annotatedCommitFromReference:branch.reference error:error];
	if (!remoteAnnotatedCommit) {
		return NO;
	}

	GTMergeAnalysis analysis = GTMergeAnalysisNone;
	GTMergePreference preference = GTMergePreferenceNone;
	BOOL success = [self analyzeMerge:&analysis preference:&preference fromAnnotatedCommits:@[remoteAnnotatedCommit] error:error];
	if (!success) {
		return NO;
	}

	if (analysis & GTMergeAnalysisUpToDate) {
		// Nothing to do
		return YES;
	} else if (analysis & GTMergeAnalysisFastForward && preference == GTMergePreferenceNoFastForward) {
		// Fast-forward branch
		if (error != NULL) {
			*error = [NSError git_errorFor:GIT_ERROR description:@"Normal merge not possible for branch '%@'", branch.name];
		}
		return NO;
	} else if (analysis & GTMergeAnalysisNormal && preference == GTMergePreferenceFastForwardOnly) {
		if (error != NULL) {
			*error = [NSError git_errorFor:GIT_ERROR description:@"Fast-forward not possible for branch '%@'", branch.name];
		}
		return NO;
	}

	if (analysis & GTMergeAnalysisFastForward) {
		NSString *message = [NSString stringWithFormat:@"merge %@: Fast-forward", branch.name];
		GTReference *reference = [localBranch.reference referenceByUpdatingTarget:remoteCommit.SHA message:message error:error];
		BOOL checkoutSuccess = [self checkoutReference:reference options:[GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategyForce] error:error];
		return checkoutSuccess;
	}

	// Do normal merge
	GTIndex *index = [self indexWithError:error];
	if (index == nil) {
		return NO;
	}

	NSError *mergeError = nil;
	GTCheckoutOptions *checkoutOptions = [GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategySafe|GTCheckoutStrategyAllowConflicts];

	success = [self mergeAnnotatedCommits:@[remoteAnnotatedCommit]
							 mergeOptions:nil
						  checkoutOptions:checkoutOptions
									error:&mergeError];
	if (!success) {
		if (error != NULL) {
			*error = mergeError;
		}
		return NO;
	}

	if (![index refresh:error]) {
		return NO;
	}

	if (index.hasConflicts) {
		if (error) {
			NSMutableArray <NSString *> *files = [NSMutableArray array];
			[index enumerateConflictedFilesWithError:error usingBlock:^(GTIndexEntry * _Nonnull ancestor, GTIndexEntry * _Nonnull ours, GTIndexEntry * _Nonnull theirs, BOOL * _Nonnull stop) {
				[files addObject:ours.path];
			}];
			NSDictionary *userInfo = @{GTPullMergeConflictedFiles: files};
			*error = [NSError git_errorFor:GIT_EMERGECONFLICT description:@"Merge conflict" userInfo:userInfo failureReason:nil];
		}
		return NO;
	}

	GTTree *mergedTree = [index writeTree:error];
	if (mergedTree == nil) {
		return NO;
	}

	// Create merge commit
	NSError *mergeMsgError = nil;
	NSURL *mergeMsgFile = [[self gitDirectoryURL] URLByAppendingPathComponent:@"MERGE_MSG"];
	NSString *message = [NSString stringWithContentsOfURL:mergeMsgFile
												 encoding:NSUTF8StringEncoding
													error:&mergeMsgError];
	if (!message) {
		message = [NSString stringWithFormat:@"Merge branch '%@'", localBranch.shortName];
	}

	NSArray *parents = @[ localCommit, remoteCommit ];
	GTCommit *mergeCommit = [self createCommitWithTree:mergedTree message:message parents:parents updatingReferenceNamed:localBranch.reference.name error:error];
	if (!mergeCommit) {
		return NO;
	}

	success = [self checkoutReference:localBranch.reference options:[GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategyForce] error:error];
	return success;
}

- (NSString * _Nullable)contentsOfDiffWithAncestor:(GTIndexEntry *)ancestor ourSide:(GTIndexEntry *)ourSide theirSide:(GTIndexEntry *)theirSide error:(NSError **)error {

	GTObjectDatabase *database = [self objectDatabaseWithError:error];
	if (database == nil) {
		return nil;
	}

	// initialize the ancestor's merge file input
	git_merge_file_input ancestorInput;
	int gitError = git_merge_file_init_input(&ancestorInput, GIT_MERGE_FILE_INPUT_VERSION);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create merge file input for ancestor"];
		return nil;
	}

	git_oid ancestorId = ancestor.git_index_entry->id;
	GTOID *ancestorOID = [[GTOID alloc] initWithGitOid:&ancestorId];
	NSData *ancestorData = [[database objectWithOID:ancestorOID error: error] data];
	if (ancestorData == nil) {
		return nil;
	}
	ancestorInput.ptr = ancestorData.bytes;
	ancestorInput.size = ancestorData.length;


	// initialize our merge file input
	git_merge_file_input ourInput;
	gitError = git_merge_file_init_input(&ourInput, GIT_MERGE_FILE_INPUT_VERSION);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create merge file input for our side"];
		return nil;
	}

	git_oid ourId = ourSide.git_index_entry->id;
	GTOID *ourOID = [[GTOID alloc] initWithGitOid:&ourId];
	NSData *ourData = [[database objectWithOID:ourOID error: error] data];
	if (ourData == nil) {
		return nil;
	}
	ourInput.ptr = ourData.bytes;
	ourInput.size = ourData.length;


	// initialize their merge file input
	git_merge_file_input theirInput;
	gitError = git_merge_file_init_input(&theirInput, GIT_MERGE_FILE_INPUT_VERSION);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create merge file input other side"];
		return nil;
	}

	git_oid theirId = theirSide.git_index_entry->id;
	GTOID *theirOID = [[GTOID alloc] initWithGitOid:&theirId];
	NSData *theirData = [[database objectWithOID:theirOID error: error] data];
	if (theirData == nil) {
		return nil;
	}
	theirInput.ptr = theirData.bytes;
	theirInput.size = theirData.length;


	git_merge_file_result result;
	gitError = git_merge_file(&result, &ancestorInput, &ourInput, &theirInput, nil);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create merge file"];
		return nil;
	}

	NSString *mergedContent = [[NSString alloc] initWithBytes:result.ptr length:result.len encoding:NSUTF8StringEncoding];

	git_merge_file_result_free(&result);

	return mergedContent;
}

- (BOOL)analyzeMerge:(GTMergeAnalysis *)analysis fromBranch:(GTBranch *)fromBranch error:(NSError **)error {
	NSParameterAssert(analysis != NULL);
	NSParameterAssert(fromBranch != nil);

	GTCommit *fromCommit = [fromBranch targetCommitWithError:error];
	if (!fromCommit) {
		return NO;
	}

	GTAnnotatedCommit *annotatedCommit = [GTAnnotatedCommit annotatedCommitFromReference:fromBranch.reference error:error];
	if (!annotatedCommit) {
		return NO;
	}

	return [self analyzeMerge:analysis preference:NULL fromAnnotatedCommits:@[annotatedCommit] error:error];
}

@end
