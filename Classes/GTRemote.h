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

// Auto Tag settings. See git_remote_autotag_option_t.
typedef enum {
	GTRemoteDownloadTagsAuto = GIT_REMOTE_DOWNLOAD_TAGS_AUTO,
	GTRemoteDownloadTagsNone = GIT_REMOTE_DOWNLOAD_TAGS_NONE,
	GTRemoteDownloadTagsAll = GIT_REMOTE_DOWNLOAD_TAGS_ALL,
} GTRemoteAutoTagOption;


@interface GTRemote : NSObject

@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, copy) NSString *pushURLString;
@property (nonatomic, readonly, getter=isConnected) BOOL connected;
@property (nonatomic) BOOL updatesFetchHead;
@property (nonatomic) GTRemoteAutoTagOption autoTag;

// Tests if a URL is valid
+ (BOOL)isValidURL:(NSString *)url;

// Tests if a URL is supported
+ (BOOL)isSupportedURL:(NSString *)url;

// Tests if a name is valid
+ (BOOL)isValidName:(NSString *)name;

// Create a new remote in a repository.
//
// name - The name for the new remote.
// url  - The origin URL for the remote.
// repo - The repository the remote should be created in.
//
// Returns a new remote, or nil if an error occurred
+ (instancetype)createRemoteWithName:(NSString *)name url:(NSString *)url inRepository:(GTRepository *)repo;

// Load a remote from a repository.
//
// name - The name for the new remote.
// url  - The origin URL for the remote.
// repo - The repository the remote should be created in.
//
// Returns the loaded remote, or nil if an error occurred.
+ (instancetype)remoteWithName:(NSString *)name inRepository:(GTRepository *)repo;

// Initializes a GTRemote object.
//
// Depending on the presence or absence of the `url` parameter, it will either
// create a new remote or load an exisiting one, respectively.
// This is the designated initializer for `GTRemote`.
//
// name  - The name of the remote.
// url   - Optional url for the remote.
// repo  - The repository containing the remote.
// error - Will be set if an error occurs.
- (instancetype)initWithName:(NSString *)name url:(NSString *)url inRepository:(GTRepository *)repo error:(NSError **)error;

// Initialize a remote from a `git_remote`.
- (id)initWithGitRemote:(git_remote *)remote inRepository:(GTRepository *)repo;

// The underlying `git_remote` object.
- (git_remote *)git_remote __attribute__((objc_returns_inner_pointer));

// Rename the remote.
//
// name - The new name for the remote.
// error - Will be set if an error occurs.
//
// Return YES if successful, NO otherwise.
- (BOOL)rename:(NSString *)name error:(NSError **)error;

// Fetch the remote.
//
// error         - Will be set if an error occurs.
// credBlock     - A block that will be called if the remote requires authentification.
// progressBlock - A block that will be called during the operation to report its progression.
//
// Returns YES if successful, NO otherwise.
- (BOOL)fetchWithError:(NSError **)error credentials:(int (^)(git_cred **cred, GTCredentialType allowedTypes, NSString *url, NSString *username))credBlock progress:(void (^)(const git_transfer_progress *stats, BOOL *stop))progressBlock;

@end
