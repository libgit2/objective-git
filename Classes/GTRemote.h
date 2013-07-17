//
//  GTRemote.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@class GTRepository;
@class GTOID;
@class GTReference;

typedef enum {
	GTCredentialTypeUserPassPlaintext = GIT_CREDTYPE_USERPASS_PLAINTEXT,
	GTCredentialTypeSSHKeyFilePassPhrase = GIT_CREDTYPE_SSH_KEYFILE_PASSPHRASE,
	GTCredentialTypeSSHPublicKey = GIT_CREDTYPE_SSH_PUBLICKEY,
} GTCredentialType;

typedef enum {
	GTRemoteCompletionTypeDownload = GIT_REMOTE_COMPLETION_DOWNLOAD,
	GTRemoteCompletionTypeIndexing = GIT_REMOTE_COMPLETION_INDEXING,
	GTRemoteCompletionTypeError = GIT_REMOTE_COMPLETION_ERROR,
} GTRemoteCompletionType;

@interface GTRemote : NSObject

@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *URLString;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;


+ (instancetype)remoteWithName:(NSString *)name inRepository:(GTRepository *)repo;
- (instancetype)initWithName:(NSString *)name inRepository:(GTRepository *)repo;

- (id)initWithGitRemote:(git_remote *)remote;

// The underlying `git_remote` object.
- (git_remote *)git_remote __attribute__((objc_returns_inner_pointer));

- (BOOL)fetchWithError:(NSError **)error credentials:(int (^)(git_cred **cred, GTCredentialType allowedTypes, NSString *url, NSString *username))credBlock progress:(void (^)(NSString *message, int length, BOOL *stop))progressBlock completion:(int (^)(GTRemoteCompletionType type, BOOL *stop))completionBlock updateTips:(int (^)(GTReference *ref, GTOID *a, GTOID *b, BOOL *stop))updateTipsBlock;

- (void)cancelOperation;
@end
