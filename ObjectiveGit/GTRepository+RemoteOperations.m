//
//  GTRepository+RemoteOperations.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 18/11/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository+RemoteOperations.h"

#import "EXTScope.h"
#import "GTCredential.h"
#import "GTCredential+Private.h"
#import "GTFetchHeadEntry.h"
#import "GTOID.h"
#import "GTRemote.h"
#import "GTSignature.h"
#import "NSError+Git.h"

#import "git2/errors.h"
#import "git2/remote.h"
#import "git2/push.h"

NSString *const GTRepositoryRemoteOptionsCredentialProvider = @"GTRepositoryRemoteOptionsCredentialProvider";

typedef void (^GTRemoteFetchTransferProgressBlock)(const git_transfer_progress *stats, BOOL *stop);
typedef void (^GTRemotePushTransferProgressBlock)(unsigned int current, unsigned int total, size_t bytes, BOOL *stop);

@implementation GTRepository (RemoteOperations)

#pragma mark -
#pragma mark Common Remote code

typedef struct {
	GTCredentialAcquireCallbackInfo credProvider;
	__unsafe_unretained GTRemoteFetchTransferProgressBlock fetchProgressBlock;
	__unsafe_unretained GTRemotePushTransferProgressBlock pushProgressBlock;
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

int GTRemotePushTransferProgressCallback(unsigned int current, unsigned int total, size_t bytes, void *payload) {
	GTRemoteConnectionInfo *pushPayload = payload;

	BOOL stop = NO;
	if (pushPayload->pushProgressBlock) {
		pushPayload->pushProgressBlock(current, total, bytes, &stop);
	}

	return (stop == YES ? GIT_EUSER : 0);
}

static int GTRemotePushRefspecStatusCallback(const char *ref, const char *msg, void *data) {
	if (msg != NULL) {
		return GIT_ERROR;
	}

	return GIT_OK;
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

#pragma mark - Push (Public)

- (BOOL)pushBranch:(GTBranch *)branch toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemotePushTransferProgressBlock)progressBlock {
	return [self pushBranches:@[ branch ] toRemote:remote withOptions:options error:error progress:progressBlock];
}

- (BOOL)pushBranches:(NSArray *)branches toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemotePushTransferProgressBlock)progressBlock {
	NSMutableArray *refspecs = nil;
	if (branches.count != 0) {
		// Build refspecs for the passed in branches
		refspecs = [NSMutableArray arrayWithCapacity:branches.count];
		for (GTBranch *branch in branches) {
			// Assumes upstream branch reference has same name as local tracking branch
			[refspecs addObject:[NSString stringWithFormat:@"%@:%@", branch.reference.name, branch.reference.name]];
		}
	}

	return [self pushRefspecs:refspecs toRemote:remote withOptions:options error:error progress:progressBlock];
}

#pragma mark - Push (Private)

- (BOOL)pushRefspecs:(NSArray *)refspecs toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemotePushTransferProgressBlock)progressBlock {
	int gitError;
	GTCredentialProvider *credProvider = options[GTRepositoryRemoteOptionsCredentialProvider];

	GTRemoteConnectionInfo connectionInfo = {
		.credProvider = { .credProvider = credProvider },
		.direction = GIT_DIRECTION_PUSH,
		.pushProgressBlock = progressBlock,
	};

	git_remote_callbacks remote_callbacks = {
		.version = GIT_REMOTE_CALLBACKS_VERSION,
		.credentials = (credProvider != nil ? GTCredentialAcquireCallback : NULL),
		.transfer_progress = GTRemoteFetchTransferProgressCallback,
		.payload = &connectionInfo,
	};

	gitError = git_remote_set_callbacks(remote.git_remote, &remote_callbacks);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to set callbacks on remote"];
		return NO;
	}

	gitError = git_remote_connect(remote.git_remote, GIT_DIRECTION_PUSH);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to connect remote"];
		return NO;
	}
	@onExit {
		git_remote_disconnect(remote.git_remote);
		// Clear out callbacks by overwriting with an effectively empty git_remote_callbacks struct
		git_remote_set_callbacks(remote.git_remote, &((git_remote_callbacks)GIT_REMOTE_CALLBACKS_INIT));
	};

	git_push *push;
	gitError = git_push_new(&push, remote.git_remote);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Push object creation failed" failureReason:@"Failed to create push object for remote \"%@\"", self];
		return NO;
	}
	@onExit {
		git_push_free(push);
	};

	git_push_options push_options = { //GIT_PUSH_OPTIONS_INIT;
		.version = GIT_PUSH_OPTIONS_VERSION,
		.pb_parallelism = 1,
	};
	gitError = git_push_set_options(push, &push_options);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to add options"];
		return NO;
	}

	GTRemoteConnectionInfo payload = {
		.pushProgressBlock = progressBlock,
	};
	gitError = git_push_set_callbacks(push, NULL, NULL, GTRemotePushTransferProgressCallback, &payload);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Setting push callbacks failed"];
		return NO;
	}

	for (NSString *refspec in refspecs) {
		gitError = git_push_add_refspec(push, refspec.UTF8String);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Adding reference failed" failureReason:@"Failed to add refspec \"%@\" to push object", refspec];
			return NO;
		}
	}

	gitError = git_push_finish(push);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Push to remote failed"];
		return NO;
	}

	int unpackSuccessful = git_push_unpack_ok(push);
	if (unpackSuccessful == 0) {
		if (error != NULL) *error = [NSError errorWithDomain:GTGitErrorDomain code:GIT_ERROR userInfo:@{ NSLocalizedDescriptionKey: @"Unpacking failed" }];
		return NO;
	}

	gitError = git_push_update_tips(push, self.userSignatureForNow.git_signature, NULL);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Update tips failed"];
		return NO;
	}

	gitError = git_push_status_foreach(push, GTRemotePushRefspecStatusCallback, NULL);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"One or references failed to update"];
		return NO;
	}

	return YES;
}

@end
