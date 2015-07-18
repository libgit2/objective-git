//
//  GTSubmodule.h
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-05-29.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTObject.h"

#import "git2/buffer.h"
#import "git2/submodule.h"

@class GTOID;

/// Determines which kinds of changes within the submodule repository will be
/// ignored when retrieving its status.
///
/// These flags are mutually exclusive.
typedef NS_ENUM(NSInteger, GTSubmoduleIgnoreRule) {
	GTSubmoduleIgnoreUnspecified = GIT_SUBMODULE_IGNORE_UNSPECIFIED,
	GTSubmoduleIgnoreNone = GIT_SUBMODULE_IGNORE_NONE,
	GTSubmoduleIgnoreUntracked = GIT_SUBMODULE_IGNORE_UNTRACKED,
	GTSubmoduleIgnoreDirty = GIT_SUBMODULE_IGNORE_DIRTY,
	GTSubmoduleIgnoreAll = GIT_SUBMODULE_IGNORE_ALL
};

/// Describes the status of a submodule.
///
/// These flags may be ORed together.
typedef NS_OPTIONS(NSInteger, GTSubmoduleStatus) {
	GTSubmoduleStatusUnknown = 0,

	GTSubmoduleStatusExistsInHEAD = GIT_SUBMODULE_STATUS_IN_HEAD,
	GTSubmoduleStatusExistsInIndex = GIT_SUBMODULE_STATUS_IN_INDEX,
	GTSubmoduleStatusExistsInConfig = GIT_SUBMODULE_STATUS_IN_CONFIG,
	GTSubmoduleStatusExistsInWorkingDirectory = GIT_SUBMODULE_STATUS_IN_WD,

	GTSubmoduleStatusAddedToIndex = GIT_SUBMODULE_STATUS_INDEX_ADDED,
	GTSubmoduleStatusDeletedFromIndex = GIT_SUBMODULE_STATUS_INDEX_DELETED,
	GTSubmoduleStatusModifiedInIndex = GIT_SUBMODULE_STATUS_INDEX_MODIFIED,

	GTSubmoduleStatusUninitialized = GIT_SUBMODULE_STATUS_WD_UNINITIALIZED,
	GTSubmoduleStatusAddedToWorkingDirectory = GIT_SUBMODULE_STATUS_WD_ADDED,
	GTSubmoduleStatusDeletedFromWorkingDirectory = GIT_SUBMODULE_STATUS_WD_DELETED,
	GTSubmoduleStatusModifiedInWorkingDirectory = GIT_SUBMODULE_STATUS_WD_MODIFIED,

	GTSubmoduleStatusDirtyIndex = GIT_SUBMODULE_STATUS_WD_INDEX_MODIFIED,
	GTSubmoduleStatusDirtyWorkingDirectory = GIT_SUBMODULE_STATUS_WD_WD_MODIFIED,
	GTSubmoduleStatusUntrackedFilesInWorkingDirectory = GIT_SUBMODULE_STATUS_WD_UNTRACKED
};

NS_ASSUME_NONNULL_BEGIN

/// Represents a submodule within its parent repository.
@interface GTSubmodule : NSObject

/// The repository that this submodule lives within.
@property (nonatomic, strong, readonly) GTRepository *parentRepository;

/// The current ignore rule for this submodule.
@property (nonatomic, readonly, assign) GTSubmoduleIgnoreRule ignoreRule;

/// The OID that the submodule is pinned to in the parent repository's index.
///
/// If the submodule is not in the index, this will be nil.
@property (nonatomic, strong, readonly, nullable) GTOID *indexOID;

/// The OID that the submodule is pinned to in the parent repository's HEAD
/// commit.
///
/// If the submodule is not in HEAD, this will be nil.
@property (nonatomic, strong, readonly, nullable) GTOID *HEADOID;

/// The OID that is checked out in the submodule repository.
///
/// If the submodule is not checked out, this will be nil.
@property (nonatomic, strong, readonly, nullable) GTOID *workingDirectoryOID;

/// The name of this submodule.
@property (nonatomic, copy, readonly, nullable) NSString *name;

/// The path to this submodule, relative to its parent repository's root.
@property (nonatomic, copy, readonly, nullable) NSString *path;

/// The remote URL provided for this submodule, read from the parent repository's
/// `.git/config` or `.gitmodules` file.
@property (nonatomic, copy, readonly, nullable) NSString *URLString;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver to wrap the given submodule object. Designated initializer.
///
/// submodule  - The submodule to wrap. The receiver will not own this object, so
///              it must not be freed while the GTSubmodule is alive. This must
///              not be NULL.
/// repository - The repository that contains the submodule. This must not be
///              nil.
///
/// Returns an initialized GTSubmodule, or nil if an error occurs.
- (nullable instancetype)initWithGitSubmodule:(git_submodule *)submodule parentRepository:(GTRepository *)repository NS_DESIGNATED_INITIALIZER;

/// The underlying `git_submodule` object.
- (git_submodule *)git_submodule __attribute__((objc_returns_inner_pointer));

/// Reloads the receiver's configuration from the parent repository.
///
/// This will mutate properties on the receiver.
///
/// Returns whether reloading succeeded.
- (BOOL)reload:(NSError **)error;

/// Write a new ignore rule to disk and get the resulting submodule. The
/// receiver will not have the new ignore rule. To update the receiver, call
/// `-reload:`.
///
/// ignoreRule - The ignore rule.
/// error      - The error if one occurred.
///
/// Returns the updated submodule or nil if an error occurred.
- (nullable GTSubmodule *)submoduleByUpdatingIgnoreRule:(GTSubmoduleIgnoreRule)ignoreRule error:(NSError **)error;

/// Synchronizes the submodule repository's configuration files with the settings
/// from the parent repository.
///
/// Returns whether the synchronization succeeded.
- (BOOL)sync:(NSError **)error;

/// Opens the submodule repository.
///
/// If the submodule is not currently checked out, this will fail.
///
/// Returns the opened repository, or nil if an error occurs.
- (nullable GTRepository *)submoduleRepository:(NSError **)error;

/// Calls `-statusWithIgnoreRule:error:` with the submodule's ignore rule.
- (GTSubmoduleStatus)status:(NSError **)error;

/// Determine the status for the submodule using the given ignore rule.
///
/// ignoreRule - The ignore rule to use in calculating status.
/// error      - The error if one occurred.
///
/// Returns the status or `GTSubmoduleStatusUnknown` if an error occurred.
- (GTSubmoduleStatus)statusWithIgnoreRule:(GTSubmoduleIgnoreRule)ignoreRule error:(NSError **)error;

/// Initializes the submodule by copying its information into the parent
/// repository's `.git/config` file. This is equivalent to `git submodule init`
/// on the command line.
///
/// overwrite - Whether to force an update to the `.git/config` file. If NO,
///             existing entries will not be overwritten.
/// error     - If not NULL, set to any error that occurs.
///
/// Returns whether the initialization succeeded.
- (BOOL)writeToParentConfigurationDestructively:(BOOL)overwrite error:(NSError **)error;

/// Add the current HEAD to the parent repository's index.
///
/// Note that it does *not* write the index.
///
/// error - The error if one occurred.
///
/// Returns whether the add was successful.
- (BOOL)addToIndex:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
