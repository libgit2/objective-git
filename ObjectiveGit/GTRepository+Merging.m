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

typedef void (^GTRemoteFetchTransferProgressBlock)(const git_transfer_progress *stats, BOOL *stop);

@implementation GTRepository (Merging)

typedef void (^GTRepositoryEnumerateMergeHeadEntryBlock)(GTCommit *entry, BOOL *stop);

typedef struct {
	__unsafe_unretained GTRepository *repository;
	__unsafe_unretained GTRepositoryEnumerateMergeHeadEntryBlock enumerationBlock;
} GTEnumerateMergeHeadEntriesPayload;

int GTMergeHeadEntriesCallback(const git_oid *oid, void *payload) {
	GTEnumerateMergeHeadEntriesPayload *entriesPayload = payload;

	GTRepository *repository = entriesPayload->repository;
	GTRepositoryEnumerateMergeHeadEntryBlock enumerationBlock = entriesPayload->enumerationBlock;

	GTCommit *commit = [repository lookUpObjectByOID:[GTOID oidWithGitOid:oid] objectType:GTObjectTypeCommit error:NULL];

	BOOL stop = NO;

	enumerationBlock(commit, &stop);

	return (stop == YES ? GIT_EUSER : 0);
}

- (BOOL)enumerateMergeHeadEntriesWithError:(NSError **)error usingBlock:(void (^)(GTCommit *mergeHeadEntry, BOOL *stop))block {
	NSParameterAssert(block != nil);

	GTEnumerateMergeHeadEntriesPayload payload = {
		.repository = self,
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

	[self enumerateMergeHeadEntriesWithError:error usingBlock:^(GTCommit *mergeHeadEntry, BOOL *stop) {
		[entries addObject:mergeHeadEntry];

		*stop = NO;
	}];

	return entries;
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
