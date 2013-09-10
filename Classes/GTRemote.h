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
@class GTCredentialProvider;

// Auto Tag settings. See `git_remote_autotag_option_t`.
typedef enum {
	GTRemoteDownloadTagsAuto = GIT_REMOTE_DOWNLOAD_TAGS_AUTO,
	GTRemoteDownloadTagsNone = GIT_REMOTE_DOWNLOAD_TAGS_NONE,
	GTRemoteDownloadTagsAll = GIT_REMOTE_DOWNLOAD_TAGS_ALL,
} GTRemoteAutoTagOption;

// A class representing a remote for a git repository.
//
// Analogous to `git_remote` in libgit2.
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
// Defaults to YES.
@property (nonatomic) BOOL updatesFetchHead;

// The auto-tag setting for the remote.
@property (nonatomic) GTRemoteAutoTagOption autoTag;

// The fetch refspecs for this remote.
//
// This array will contain NSStrings of the form
// `+refs/heads/*:refs/remotes/REMOTE/*`.
@property (nonatomic, readonly, copy) NSArray *fetchRefspecs;

// Tests if a URL is supported (e.g. it's a supported URL scheme)
+ (BOOL)isSupportedURL:(NSString *)URL;

// Tests if a URL is valid (e.g. it actually makes sense as a URL)
+ (BOOL)isValidURL:(NSString *)URL;

// Tests if a name is valid
+ (BOOL)isValidRemoteName:(NSString *)name;

// Create a new remote in a repository.
//
// name - The name for the new remote.
// URL  - The origin URL for the remote.
// repo - The repository the remote should be created in.
// error - Will be set if an error occurs.
//
// Returns a new remote, or nil if an error occurred
+ (instancetype)createRemoteWithName:(NSString *)name url:(NSString *)URL inRepository:(GTRepository *)repo error:(NSError **)error;

// Load a remote from a repository.
//
// name - The name for the new remote.
// repo - The repository the remote should be created in.
// error - Will be set if an error occurs.
//
// Returns the loaded remote, or nil if an error occurred.
+ (instancetype)remoteWithName:(NSString *)name inRepository:(GTRepository *)repo error:(NSError **)error;

// Initialize a remote from a `git_remote`.
//
// remote - The underlying `git_remote` object.
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

// Updates the URL string for this remote.
//
// URLString - The URLString to update to. May not be nil.
// error     - If not NULL, this will be set to any error that occurs when
//             updating the URLString or saving the remote.
//
// Returns YES if the URLString was successfully updated, NO and an error
// if updating or saving the remote failed.
- (BOOL)updateURLString:(NSString *)URLString error:(NSError **)error;

// Adds a fetch refspec to this remote.
//
// fetchRefspec - The fetch refspec string to add. May not be nil.
// error        - If not NULL, this will be set to any error that occurs
//                when adding the refspec or saving the remote.
//
// Returns YES if there is the refspec is successfully added
// or a matching refspec is already present, NO and an error if
// adding the refspec or saving the remote failed.
- (BOOL)addFetchRefspec:(NSString *)fetchRefspec error:(NSError **)error;

// Removes the first fetchRefspec that matches.
//
// fetchRefspec - The fetch refspec string to remove. May not be nil.
// error        - If not NULL, this will be set to any error that occurs
//                when removing the refspec or saving the remote.
//
// Returns YES if the matching refspec is found and removed, or if no matching
// refspec was found. NO and error is returned if a matching refspec was found
// but could not be removed, or saving the remote failed.
- (BOOL)removeFetchRefspec:(NSString *)fetchRefspec error:(NSError **)error;

// Fetch the remote.
//
// credProvider  - The credential provider to use if the remote requires authentification.
// error         - Will be set if an error occurs.
// progressBlock - A block that will be called during the operation to report its progression.
//
// Returns YES if successful, NO otherwise.
- (BOOL)fetchWithCredentialProvider:(GTCredentialProvider *)credProvider error:(NSError **)error progress:(void (^)(const git_transfer_progress *stats, BOOL *stop))progressBlock;

- (BOOL)pushReferences:(NSArray *)references credentialProvider:(GTCredentialProvider *)credProvider error:(NSError **)error progress:(void (^)(const git_transfer_progress *stats, BOOL *stop))progressBlock;
@end
