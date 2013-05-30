//
//  GTSubmodule.h
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-05-29.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTObject.h"

@class GTOID;

// Determines which kinds of changes within the submodule repository will be
// ignored when retrieving its status.
//
// These flags are mutually exclusive.
typedef enum : git_submodule_ignore_t {
	GTSubmoduleIgnoreDefault = GIT_SUBMODULE_IGNORE_DEFAULT,
	GTSubmoduleIgnoreNone = GIT_SUBMODULE_IGNORE_NONE,
	GTSubmoduleIgnoreUntracked = GIT_SUBMODULE_IGNORE_UNTRACKED,
	GTSubmoduleIgnoreDirty = GIT_SUBMODULE_IGNORE_DIRTY,
	GTSubmoduleIgnoreAll = GIT_SUBMODULE_IGNORE_ALL
} GTSubmoduleIgnoreRule;

// Describes the status of a submodule.
//
// These flags may be ORed together.
typedef enum : git_submodule_status_t {
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
} GTSubmoduleStatus;

// Represents a submodule within its parent repository.
@interface GTSubmodule : NSObject <GTObject>

// The repository that this submodule lives within.
@property (nonatomic, strong, readonly) GTRepository *repository;

// The underlying `git_submodule`.
@property (nonatomic, assign, readonly) git_submodule *git_submodule;

// The current ignore rule for this submodule.
//
// Setting this property will only update the rule in memory, not on disk.
@property (nonatomic, assign) GTSubmoduleIgnoreRule ignoreRule;

// The OID that the submodule is pinned to in the parent repository's index.
//
// If the submodule is not in the index, this will be nil.
@property (nonatomic, strong, readonly) GTOID *indexOID;

// The OID that the submodule is pinned to in the parent repository's HEAD
// commit.
//
// If the submodule is not in HEAD, this will be nil.
@property (nonatomic, strong, readonly) GTOID *HEADOID;

// The OID that is checked out in the submodule repository.
//
// If the submodule is not checked out, this will be nil.
@property (nonatomic, strong, readonly) GTOID *workingDirectoryOID;

// The name of this submodule.
@property (nonatomic, copy, readonly) NSString *name;

// Initializes the receiver to wrap the given submodule object.
- (id)initWithGitSubmodule:(git_submodule *)submodule parentRepository:(GTRepository *)repository;

// Synchronizes the submodule repository's configuration files with the settings
// from the parent repository.
//
// Returns whether the synchronization succeeded.
- (BOOL)syncWithError:(NSError **)error;

// Opens the submodule repository.
//
// If the submodule is not currently checked out, this will fail.
//
// Returns the opened repository, or nil if an error occurs.
- (GTRepository *)submoduleRepositoryWithError:(NSError **)error;

// Determines the status for the submodule.
//
// Returns the status, or `GTSubmoduleStatusUnknown` if an error occurs.
- (GTSubmoduleStatus)statusWithError:(NSError **)error;

@end
