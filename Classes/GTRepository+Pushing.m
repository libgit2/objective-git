//
//  GTRepository+Pushing.m
//  ObjectiveGitFramework
//
//  Created by John Beatty on 1/12/14.
//  Copyright (c) 2014 Objective Products LLC All rights reserved.
//

#import "NSError+Git.h"
#import "GTRepository+Pushing.h"
#import "GTConfiguration.h"
#import "GTRemote.h"
#import "GTCredential.h"
#import "GTCredential+Private.h"
#import "GTBranch.h"
#import "GTSignature.h"

NSString *const GTRepositoryPushingOptionsCredentialProvider = @"GTRepositoryPushingOptionsCredentialProvider";

@implementation GTRepository (Pushing)

typedef void(^GTTransferProgressBlock)(const git_transfer_progress *progress);

struct GTPushPayload {
	// credProvider must be first for compatibility with GTCredentialAcquireCallbackInfo
	__unsafe_unretained GTCredentialProvider *credProvider;
	__unsafe_unretained GTTransferProgressBlock transferProgressBlock;
};

static int pushTransferProgressCallback(const git_transfer_progress *progress, void *payload) {
	if (payload == NULL) return 0;
	struct GTPushPayload *pld = payload;
	if (pld->transferProgressBlock == NULL) return 0;
	pld->transferProgressBlock(progress);
	return GIT_OK;
}

static int pushRefspecCallback(const char *ref, const char *msg, void *data) {
	NSLog(@"%s %s %s", __PRETTY_FUNCTION__, ref, msg);
	return GIT_OK;
}

static int pushCompletionCallback(git_remote_completion_type type, void *data) {
	NSLog(@"%s", __PRETTY_FUNCTION__);
	return GIT_OK;
}

- (void)pushBranch:(GTBranch *)branch toRemote:(GTRemote *)_remote options:(NSDictionary *)pushOptions {
	NSLog(@"%s %@", __PRETTY_FUNCTION__, [[branch reference] name]);
	NSError *error;
	git_remote* remote;
	git_push *push;
	git_push_options options = GIT_PUSH_OPTIONS_INIT;

	GTCredentialProvider *credentialProvider = pushOptions[GTRepositoryPushingOptionsCredentialProvider];

	git_remote_callbacks remote_callbacks = GIT_REMOTE_CALLBACKS_INIT;
	struct GTPushPayload payload;
	payload.credProvider = credentialProvider;
	remote_callbacks.version = GIT_REMOTE_CALLBACKS_VERSION;
	remote_callbacks.credentials = GTCredentialAcquireCallback;
	
	payload.transferProgressBlock = ^(const git_transfer_progress *progress) {
		NSLog(@"%s %d %d %d", __PRETTY_FUNCTION__, progress->total_objects, progress->received_objects, progress->local_objects );
	};
	remote_callbacks.transfer_progress = pushTransferProgressCallback;
	remote_callbacks.completion = pushCompletionCallback;
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
	gitError = git_remote_connect(remote, GIT_DIRECTION_PUSH);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to open remote connection."];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	gitError = git_push_new(&push, remote);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to create git_push object"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	gitError = git_push_set_options(push, &options);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to add options"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	gitError = git_push_add_refspec(push, [[NSString stringWithFormat:@"%@:%@", [[branch reference] name], [[branch reference] name]] UTF8String]);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to add refspec"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
		
	}
	gitError = git_push_finish(push);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to finish push"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	gitError = git_push_unpack_ok(push);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to unpack push"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	GTSignature *signature = [self userSignatureForNow];
	gitError = git_push_update_tips(push, signature.git_signature, NULL);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to update tips"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	gitError = git_push_status_foreach(push, pushRefspecCallback, NULL);
	if (gitError != GIT_OK) {
		error = [NSError git_errorFor:gitError description:@"Failed to loop through refs"];
		NSLog(@"%s %@", __PRETTY_FUNCTION__, error);
	}
	git_push_free(push);
	
}

@end
