//
//  GTCred.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 10/09/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "git2.h"

// An enum describing the data needed for authentication.
// See `git_credtype_t`.
typedef enum {
    GTCredentialTypeUserPassPlaintext = GIT_CREDTYPE_USERPASS_PLAINTEXT,
    GTCredentialTypeSSHKeyFilePassPhrase = GIT_CREDTYPE_SSH_KEYFILE_PASSPHRASE,
    GTCredentialTypeSSHPublicKey = GIT_CREDTYPE_SSH_PUBLICKEY,
} GTCredentialType;

@class GTCred;
// A typedef block for the various methods that require authentication
typedef GTCred *(^GTCredBlock)(GTCredentialType allowedTypes, NSString *URL, NSString *username);

@interface GTCred : NSObject

// Create a credential object from a username/password pair.
//
// userName - The username to authenticate as.
// password - The password belonging to that user.
//
// Return a new GTCred instance, or nil if an error occurred
+ (instancetype)credentialWithUserName:(NSString *)userName password:(NSString *)password error:(NSError **)error;

// Create a credential object from a SSH keyfile
//
// userName   - The username to authenticate as.
// publicKey  - The public key for that user.
// privateKey - The private key for that user.
// passPhrase - The passPhrase for the private key. Optional if the private key has no password.
//
// Return a new GTCred instance, or nil if an error occurred
+ (instancetype)credentialWithUserName:(NSString *)userName publicKey:(NSString *)publicKey privateKey:(NSString *)privateKey passPhrase:(NSString *)passPhrase error:(NSError **)error;

// PARTIALIMPL
+ (instancetype)credentialWithUserName:(NSString *)userName publicKey:(NSString *)publicKey signBlock:(void (^)(void))signBlock error:(NSError **)error;

- (git_cred *)git_cred __attribute__((objc_returns_inner_pointer));

@property (readonly) BOOL hasUserName;

@end
