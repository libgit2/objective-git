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

@end
