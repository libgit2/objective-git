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

@implementation GTRepository (RemoteOperations)

#pragma mark -
#pragma mark Common Remote code

typedef void (^GTRemoteFetchTransferProgressBlock)(const git_transfer_progress *stats, BOOL *stop);

typedef struct {
	// WARNING: Provider must come first to be layout-compatible with GTCredentialAcquireCallbackInfo
	__unsafe_unretained GTCredentialProvider *credProvider;
	__unsafe_unretained GTRemoteFetchTransferProgressBlock fetchProgressBlock;
	__unsafe_unretained GTRemoteFetchTransferProgressBlock pushProgressBlock;
	git_direction direction;
} GTRemoteConnectionInfo;

int GTRemoteFetchTransferProgressCallback(const git_transfer_progress *stats, void *payload) {
	GTRemoteConnectionInfo *info = payload;
	BOOL stop = NO;

	if (info->fetchProgressBlock) {
		info->fetchProgressBlock(stats, &stop);
	}

	return (stop == YES ? GIT_EUSER : 0);
}

#pragma mark -
#pragma mark Fetch

- (BOOL)fetchRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemoteFetchTransferProgressBlock)progressBlock {
//	NSArray *references = options[@"references"];
	@synchronized (self) {
		id credProvider = (options[@"credentialProvider"] ?: nil);
		GTRemoteConnectionInfo connectionInfo = {
			.credProvider = credProvider,
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

		gitError = git_remote_connect(remote.git_remote, GIT_DIRECTION_FETCH);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to connect remote"];
			return NO;
		}
		@onExit {
			git_remote_disconnect(remote.git_remote);
			// FIXME: Can't unset callbacks without asserting
			// git_remote_set_callbacks(self.git_remote, NULL);
		};

		gitError = git_remote_download(remote.git_remote);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to fetch remote"];
			return NO;
		}

		gitError = git_remote_update_tips(remote.git_remote);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to update tips"];
			return NO;
		}

		return YES;
	}
}

#pragma mark -
#pragma mark Push

typedef void (^GTRemotePushTransferProgressBlock)(unsigned int current, unsigned int total, size_t bytes, BOOL *stop);

typedef struct {
	__unsafe_unretained GTRemotePushTransferProgressBlock transferProgressBlock;
} GTRemotePushPayload;

int GTRemotePushTransferProgressCallback(unsigned int current, unsigned int total, size_t bytes, void* payload) {
	GTRemotePushPayload *pushPayload = payload;

	BOOL stop = NO;
	if (pushPayload->transferProgressBlock)
		pushPayload->transferProgressBlock(current, total, bytes, &stop);

	return (stop == YES ? GIT_EUSER : 0);
}

- (BOOL)pushRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemotePushTransferProgressBlock)progressBlock {
	NSArray *references = options[@"references"];
	NSMutableArray *refspecs = nil;
	if (references != nil && references.count != 0) {
		// Build refspecs for the passed in branches
		refspecs = [NSMutableArray arrayWithCapacity:references.count];
		for (GTReference *ref in references) {
			[refspecs addObject:[NSString stringWithFormat:@"%@:%@", ref.name, ref.name]];
		}
	}

	git_push *push;
	int gitError = git_push_new(&push, remote.git_remote);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Push object creation failed" failureReason:@"Failed to create push object for remote \"%@\"", self];
		return NO;
	}
	@onExit {
		git_push_free(push);
	};

	GTRemotePushPayload payload = {
		.transferProgressBlock = progressBlock,
	};

	for (NSString *refspec in refspecs) {
		gitError = git_push_add_refspec(push, refspec.UTF8String);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Adding reference failed" failureReason:@"Failed to add refspec \"%@\" to push object", refspec];
			return NO;
		}
	}

	gitError = git_push_set_callbacks(push, NULL, NULL, GTRemotePushTransferProgressCallback, &payload);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Setting push callbacks failed"];
		return NO;
	}

	@synchronized (self) {
		id credProvider = (options[@"credentialProvider"] ?: nil);
		GTRemoteConnectionInfo connectionInfo = {
			.credProvider = credProvider,
			.direction = GIT_DIRECTION_PUSH,
//			.pushProgressBlock = progressBlock,
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

		gitError = git_remote_connect(remote.git_remote, GIT_DIRECTION_PUSH);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to connect remote"];
			return NO;
		}
		@onExit {
			git_remote_disconnect(remote.git_remote);
			// FIXME: Can't unset callbacks without asserting
			// git_remote_set_callbacks(self.git_remote, NULL);
		};

		gitError = git_push_finish(push);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Push to remote failed"];
			return NO;
		}

		int unpackSuccessful = git_push_unpack_ok(push);
		if (unpackSuccessful == 0) {
			if (error != NULL) *error = [NSError errorWithDomain:GTGitErrorDomain code:-1 userInfo:@{ NSLocalizedDescriptionKey: @"Unpacking failed" }];
			return NO;
		}

		gitError = git_push_update_tips(push);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Update tips failed"];
			return NO;
		}

		/* TODO: libgit2 sez we should check git_push_status_foreach to see if our push succeeded */
		return YES;
	}
}

@end
