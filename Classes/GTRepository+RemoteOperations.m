//
//  GTRepository+RemoteOperations.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 18/11/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository+RemoteOperations.h"

#import "GTCredential.h"
#import "GTCredential+Private.h"
#import "EXTScope.h"

NSString *const GTRepositoryRemoteOptionsCredentialProvider = @"GTRepositoryRemoteOptionsCredentialProvider";

@implementation GTRepository (RemoteOperations)

#pragma mark -
#pragma mark Common Remote code

typedef void (^GTRemoteFetchTransferProgressBlock)(const git_transfer_progress *stats, BOOL *stop);

typedef struct {
	GTCredentialAcquireCallbackInfo credProvider;
	__unsafe_unretained GTRemoteFetchTransferProgressBlock fetchProgressBlock;
	__unsafe_unretained GTRemoteFetchTransferProgressBlock pushProgressBlock;
	git_direction direction;
} GTRemoteConnectionInfo;

int GTRemoteFetchTransferProgressCallback(const git_transfer_progress *stats, void *payload) {
	GTRemoteConnectionInfo *info = payload;
	BOOL stop = NO;

	if (info->fetchProgressBlock != nil) {
		info->fetchProgressBlock(stats, &stop);
	}

	return (stop == YES ? GIT_EUSER : 0);
}

#pragma mark -
#pragma mark Fetch

- (BOOL)fetchRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemoteFetchTransferProgressBlock)progressBlock {
	GTCredentialProvider *credProvider = options[GTRepositoryRemoteOptionsCredentialProvider];
	GTRemoteConnectionInfo connectionInfo = {
		.credProvider = {credProvider},
		.direction = GIT_DIRECTION_FETCH,
		.fetchProgressBlock = progressBlock,
	};
	git_remote_callbacks remote_callbacks = {
		.version = GIT_REMOTE_CALLBACKS_VERSION,
		.credentials = (credProvider != nil ? GTCredentialAcquireCallback : NULL),
		.transfer_progress = GTRemoteFetchTransferProgressCallback,
		.payload = &connectionInfo,
	};

	int gitError = git_remote_set_callbacks(remote.git_remote, &remote_callbacks);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to set callbacks on remote"];
		return NO;
	}

	__block git_strarray refspecs;
	gitError = git_remote_get_fetch_refspecs(&refspecs, remote.git_remote);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get fetch refspecs for remote"];
		return NO;
	}

	@onExit {
		git_strarray_free(&refspecs);
	};

	gitError = git_remote_fetch(remote.git_remote, &refspecs, self.userSignatureForNow.git_signature, NULL);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to fetch from remote"];
		return NO;
	}

	return YES;
}

#pragma mark -
#pragma mark Fetch Head enumeration

typedef void (^GTRemoteEnumerateFetchHeadEntryBlock)(GTFetchHeadEntry *entry, BOOL *stop);

typedef struct {
	__unsafe_unretained GTRepository *repository;
	__unsafe_unretained GTRemoteEnumerateFetchHeadEntryBlock enumerationBlock;
} GTEnumerateHeadEntriesPayload;

int GTFetchHeadEntriesCallback(const char *ref_name, const char *remote_url, const git_oid *oid, unsigned int is_merge, void *payload) {
	GTEnumerateHeadEntriesPayload *entriesPayload = payload;

	GTRepository *repository = entriesPayload->repository;
	GTRemoteEnumerateFetchHeadEntryBlock enumerationBlock = entriesPayload->enumerationBlock;

	GTReference *reference = [GTReference referenceByLookingUpReferencedNamed:@(ref_name) inRepository:repository error:NULL];

	GTFetchHeadEntry *entry = [[GTFetchHeadEntry alloc] initWithReference:reference remoteURLString:@(remote_url) targetOID:[GTOID oidWithGitOid:oid] isMerge:(BOOL)is_merge];

	BOOL stop = NO;

	enumerationBlock(entry, &stop);

	return (stop == YES ? GIT_EUSER : 0);
}

- (BOOL)enumerateFetchHeadEntriesWithError:(NSError **)error usingBlock:(void (^)(GTFetchHeadEntry *fetchHeadEntry, BOOL *stop))block {
	NSParameterAssert(block != nil);
	
	GTEnumerateHeadEntriesPayload payload = {
		.repository = self,
		.enumerationBlock = block,
	};
	int gitError = git_repository_fetchhead_foreach(self.git_repository, GTFetchHeadEntriesCallback, &payload);

	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get fetchhead entries"];
		return NO;
	}
	
	return YES;
}

- (NSArray *)fetchHeadEntriesWithError:(NSError **)error {
	NSMutableArray *entries = [NSMutableArray array];
	
	[self enumerateFetchHeadEntriesWithError:error usingBlock:^(GTFetchHeadEntry *fetchHeadEntry, BOOL *stop) {
		[entries addObject:fetchHeadEntry];
		
		*stop = NO;
	}];
	
	return entries;
}

@end
