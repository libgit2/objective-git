//
//  GTCred+Private.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 10/09/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTCred.h"

// If you need to authenticate an operation in libgit2, you'll have to
// have a `GTCredBlock` handy, like a parameter in the method you're writing,
// setup a GTCredAcquireCallbackInfo struct on the stack, and pass both as the
// arguments to the operation you're attempting.
//
// Example: ```
//   struct GTCredAcquireCallbackInfo info = { .credBlock = ... }
//   git_remote_set_cred_acquire_cb(&git_remote, GTCredAcquireCallback, &payload);
// ```
//
// `GTCredAcquireCallback` will act as a trampoline, and will ask the user code
// for a `GTCred` object. It is the user's responsibility to check the auth type
// and initialize its `GTCred` object correctly.

typedef struct {
	__unsafe_unretained GTCredBlock credBlock;
} GTCredAcquireCallbackInfo;

int GTCredAcquireCallback(git_cred **cred, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload);
