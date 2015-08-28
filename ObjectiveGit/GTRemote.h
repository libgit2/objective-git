//
//  GTRemote.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/remote.h"

@class GTRepository;
@class GTOID;
@class GTReference;
@class GTCredentialProvider;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const GTRemoteRenameProblematicRefSpecs;

// Auto Tag settings. See `git_remote_autotag_option_t`.
typedef enum {
	GTRemoteDownloadTagsAuto = GIT_REMOTE_DOWNLOAD_TAGS_AUTO,
	GTRemoteDownloadTagsNone = GIT_REMOTE_DOWNLOAD_TAGS_NONE,
	GTRemoteDownloadTagsAll = GIT_REMOTE_DOWNLOAD_TAGS_ALL,
} GTRemoteAutoTagOption;

/// A class representing a remote for a git repository.
///
/// Analogous to `git_remote` in libgit2.
@interface GTRemote : NSObject

/// The repository owning this remote.
@property (nonatomic, readonly, strong) GTRepository *repository;

/// The name of the remote.
@property (nonatomic, readonly, copy, nullable) NSString *name;

/// The URL string for the remote.
@property (nonatomic, readonly, copy, nullable) NSString *URLString;

/// The push URL for the remote, if provided.
@property (nonatomic, copy, nullable) NSString *pushURLString;

/// Whether the remote is connected or not.
@property (nonatomic, readonly, getter=isConnected) BOOL connected;

/// Whether the remote updates FETCH_HEAD when fetched.
/// Defaults to YES.
@property (nonatomic) BOOL updatesFetchHead;

/// The auto-tag setting for the remote.
@property (nonatomic) GTRemoteAutoTagOption autoTag;

/// The fetch refspecs for this remote.
///
/// This array will contain NSStrings of the form
/// `+refs/heads/*:refs/remotes/REMOTE/*`.
@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *fetchRefspecs;

/// The push refspecs for this remote.
///
/// This array will contain NSStrings of the form
/// `+refs/heads/*:refs/remotes/REMOTE/*`.
@property (nonatomic, readonly, copy, nullable) NSArray<NSString *> *pushRefspecs;

/// Tests if a name is valid
+ (BOOL)isValidRemoteName:(NSString *)name;

/// Create a new remote in a repository.
///
/// name      - The name for the new remote. Cannot be nil.
/// URLString - The origin URL for the remote. Cannot be nil.
/// repo      - The repository the remote should be created in. Cannot be nil.
/// error     - Will be set if an error occurs.
///
/// Returns a new remote, or nil if an error occurred
+ (nullable instancetype)createRemoteWithName:(NSString *)name URLString:(NSString *)URLString inRepository:(GTRepository *)repo error:(NSError **)error;

/// Load a remote from a repository.
///
/// name - The name for the new remote. Cannot be nil.
/// repo - The repository the remote should be looked up in. Cannot be nil.
/// error - Will be set if an error occurs.
///
/// Returns the loaded remote, or nil if an error occurred.
+ (nullable instancetype)remoteWithName:(NSString *)name inRepository:(GTRepository *)repo error:(NSError **)error;

- (instancetype)init NS_UNAVAILABLE;

/// Initialize a remote from a `git_remote`. Designated initializer.
///
/// remote - The underlying `git_remote` object. Cannot be nil.
/// repo   - The repository the remote belongs to. Cannot be nil.
///
/// Returns the initialized receiver, or nil if an error occurred.
- (nullable instancetype)initWithGitRemote:(git_remote *)remote inRepository:(GTRepository *)repo NS_DESIGNATED_INITIALIZER;

/// The underlying `git_remote` object.
- (git_remote *)git_remote __attribute__((objc_returns_inner_pointer));

/// Rename the remote.
///
/// name  - The new name for the remote. Cannot be nil.
/// error - Will be set if an error occurs. If there was an error renaming some
///         refspecs, their names will be available as an arry under the
///         `GTRemoteRenameProblematicRefSpecs` key.
///
/// Return YES if successful, NO otherwise.
- (BOOL)rename:(NSString *)name error:(NSError **)error;

/// Updates the URL string for this remote.
///
/// URLString - The URLString to update to. May not be nil.
/// error     - If not NULL, this will be set to any error that occurs when
///             updating the URLString or saving the remote.
///
/// Returns YES if the URLString was successfully updated, NO and an error
/// if updating or saving the remote failed.
- (BOOL)updateURLString:(NSString *)URLString error:(NSError **)error;

/// Adds a fetch refspec to this remote.
///
/// fetchRefspec - The fetch refspec string to add. May not be nil.
/// error        - If not NULL, this will be set to any error that occurs
///                when adding the refspec or saving the remote.
///
/// Returns YES if there is the refspec is successfully added
/// or a matching refspec is already present, NO and an error if
/// adding the refspec or saving the remote failed.
- (BOOL)addFetchRefspec:(NSString *)fetchRefspec error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
