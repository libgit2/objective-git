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

// An enum describing the authentication data needed for accessing the remote.
// See `git_credtype_t`.
typedef enum {
	GTCredentialTypeUserPassPlaintext = GIT_CREDTYPE_USERPASS_PLAINTEXT,
	GTCredentialTypeSSHKeyFilePassPhrase = GIT_CREDTYPE_SSH_KEYFILE_PASSPHRASE,
	GTCredentialTypeSSHPublicKey = GIT_CREDTYPE_SSH_PUBLICKEY,
} GTCredentialType;

// Auto Tag settings. See `git_remote_autotag_option_t`.
typedef enum {
	GTRemoteDownloadTagsAuto = GIT_REMOTE_DOWNLOAD_TAGS_AUTO,
	GTRemoteDownloadTagsNone = GIT_REMOTE_DOWNLOAD_TAGS_NONE,
	GTRemoteDownloadTagsAll = GIT_REMOTE_DOWNLOAD_TAGS_ALL,
} GTRemoteAutoTagOption;


@interface GTRemote : NSObject

// The repository owning this remote.
@property (nonatomic, readonly, strong) GTRepository *repository;

// The name of the remote.
@property (nonatomic, readonly, copy) NSString *name;

// The fetch URL for the remote.
@property (nonatomic, copy) NSString *URLString;

// The push URL for the remote, if provided.
@property (nonatomic, copy) NSString *pushURLString;

// Whether the remote is connected or not.
@property (nonatomic, readonly, getter=isConnected) BOOL connected;

// Whether the remote updates FETCH_HEAD when fetched.
@property (nonatomic) BOOL updatesFetchHead;

// The auto-tag setting for the remote.
@property (nonatomic) GTRemoteAutoTagOption autoTag;

// Tests if a URL is valid
+ (BOOL)isValidURL:(NSString *)URL;

// Tests if a URL is supported
+ (BOOL)isSupportedURL:(NSString *)URL;

// Tests if a name is valid
+ (BOOL)isValidRemoteName:(NSString *)name;

// Create a new remote in a repository.
//
// name - The name for the new remote.
// URL  - The origin URL for the remote.
// repo - The repository the remote should be created in.
//
// Returns a new remote, or nil if an error occurred
+ (instancetype)createRemoteWithName:(NSString *)name url:(NSString *)URL inRepository:(GTRepository *)repo;

// Load a remote from a repository.
//
// name - The name for the new remote.
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
// URL   - Optional URL for the remote.
// repo  - The repository containing the remote.
// error - Will be set if an error occurs.
- (instancetype)initWithName:(NSString *)name url:(NSString *)URL inRepository:(GTRepository *)repo error:(NSError **)error;

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
- (BOOL)fetchWithError:(NSError **)error credentials:(int (^)(git_cred **cred, GTCredentialType allowedTypes, NSString *URL, NSString *username))credBlock progress:(void (^)(const git_transfer_progress *stats, BOOL *stop))progressBlock;

@end
