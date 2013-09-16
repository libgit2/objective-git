//
//  GTCredential+Private.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 10/09/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTCredential.h"

// If you need to authenticate an operation in libgit2, you'll have to have
// a `GTCredentialProvider` handy, like a parameter in the method you're writing,
// setup a GTCredentialAcquireCallbackInfo struct on the stack, and pass both as
// the arguments to the operation you're attempting.
//
// Example: ```
//   struct GTCredentialAcquireCallbackInfo info = { .credProvider = myProvider }
//   git_remote_set_cred_acquire_cb(&git_remote, GTCredentialAcquireCallback, &payload);
// ```
//
// `GTCredentialAcquireCallback` will act as a trampoline, and will ask the
// `GTCredentialProvider` for a `GTCredential` object corresponding to the
// information requested by `libgit2`. It is the providers's responsibility
// to check the auth type and initialize its `GTCredential` object accordingly.

typedef struct {
	__unsafe_unretained GTCredentialProvider *credProvider;
} GTCredentialAcquireCallbackInfo;

int GTCredentialAcquireCallback(git_cred **cred, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload);
