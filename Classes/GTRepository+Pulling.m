//
//  GTRepository+Pulling.m
//  ObjectiveGitFramework
//
//  Created by John Beatty on 1/13/14.
//  Copyright (c) 2014 Objective Products LLC. All rights reserved.
//

#import "GTRepository+Pulling.h"
#import "NSError+Git.h"
#import "GTCredential+Private.h"

NSString *const GTRepositoryPullingOptionsCredentialProvider = @"GTRepositoryPullingOptionsCredentialProvider";

@implementation GTRepository (Pulling)

typedef void(^GTTransferProgressBlock)(const git_transfer_progress *progress);

struct GTPullPayload {
	// credProvider must be first for compatibility with GTCredentialAcquireCallbackInfo
	__unsafe_unretained GTCredentialProvider *credProvider;
	__unsafe_unretained GTTransferProgressBlock transferProgressBlock;
};

static int pullTransferProgressCallback(const git_transfer_progress *progress, void *payload) {
	if (payload == NULL) return 0;
	struct GTPullPayload *pld = payload;
	if (pld->transferProgressBlock == NULL) return 0;
	pld->transferProgressBlock(progress);
	return GIT_OK;
}

static int pullCompletionCallback(git_remote_completion_type type, void *data) {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	return GIT_OK;
}

- (void)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)_remote options:(NSDictionary *)pullOptions {
	NSLog(@"%s %@", __PRETTY_FUNCTION__, [[branch reference] name]);
	NSError *error;
	git_remote* remote;
	
	GTCredentialProvider *credentialProvider = pullOptions[GTRepositoryPullingOptionsCredentialProvider];
	
	git_remote_callbacks remote_callbacks = GIT_REMOTE_CALLBACKS_INIT;
	struct GTPullPayload payload;
	payload.credProvider = credentialProvider;
	remote_callbacks.version = GIT_REMOTE_CALLBACKS_VERSION;
	remote_callbacks.credentials = GTCredentialAcquireCallback;
	
	payload.transferProgressBlock = ^(const git_transfer_progress *progress) {
		NSLog(@"%s %d %d %d", __PRETTY_FUNCTION__, progress->total_objects, progress->received_objects, progress->local_objects );
	};
	remote_callbacks.transfer_progress = pullTransferProgressCallback;
	remote_callbacks.completion = pullCompletionCallback;
	remote_callbacks.payload = &payload;
	
	int gitError = git_remote_load(&remote, self.git_repository, [[_remote name] UTF8String]);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to load remote"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	
	git_remote_check_cert(remote, 0);
	gitError = git_remote_set_callbacks(remote, &remote_callbacks);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to add remote callbacks"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	
	const git_transfer_progress *stats = git_remote_stats(remote);
	
	gitError = git_remote_connect(remote, GIT_DIRECTION_FETCH);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to open remote connection."];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	gitError = git_remote_add_fetch(remote, [[NSString stringWithFormat:@"%@:%@", [[branch reference] name], [[branch reference] name]] UTF8String]);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to add refspec"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
		
	}
	
	NSLog(@"%s %s", __PRETTY_FUNCTION__, git_remote_url(remote));
	NSLog(@"%s connected? %d", __PRETTY_FUNCTION__, git_remote_connected(remote));
	GTSignature *signature = [self userSignatureForNow];
	gitError = git_remote_fetch(remote, signature.git_signature, NULL);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to download data."];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	
	if (stats->local_objects > 0) {
		printf("\rReceived %d/%d objects in %zu bytes (used %d local objects)\n",
			   stats->indexed_objects, stats->total_objects, stats->received_bytes, stats->local_objects);
	} else{
		printf("\rReceived %d/%d objects in %zu bytes\n",
			   stats->indexed_objects, stats->total_objects, stats->received_bytes);
	}
	
	git_remote_disconnect(remote);
	gitError = git_remote_update_tips(remote, signature.git_signature, NULL);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to update tips."];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	
	git_remote_free(remote);
}

@end
