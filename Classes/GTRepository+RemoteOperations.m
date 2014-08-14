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
	@synchronized (self) {
		GTCredentialProvider *credProvider = (options[GTRepositoryRemoteOptionsCredentialProvider] ?: nil);
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
		
		gitError = git_remote_fetch(remote.git_remote, self.userSignatureForNow.git_signature, NULL);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to fetch from remote"];
			return NO;
		}

		return YES;
	}
}

@end
