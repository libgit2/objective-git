//
//  GTRepository+Status.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

@class GTStatusDelta;

// An enum representing the status of a file
// See git_status_t
typedef enum {
	GTFileStatusCurrent = GIT_STATUS_CURRENT,

	GTFileStatusNewInIndex         = GIT_STATUS_INDEX_NEW,
	GTFileStatusModifiedInIndex    = GIT_STATUS_INDEX_MODIFIED,
	GTFileStatusDeletedInIndex     = GIT_STATUS_INDEX_DELETED,
	GTFileStatusRenamedInIndex     = GIT_STATUS_INDEX_RENAMED,
	GTFileStatusTypeChangedInIndex = GIT_STATUS_INDEX_TYPECHANGE,

	GTFileStatusNewInWorktree         = GIT_STATUS_WT_NEW,
	GTFileStatusModifiedInWorktree    = GIT_STATUS_WT_MODIFIED,
	GTFileStatusDeletedInWorktree     = GIT_STATUS_WT_DELETED,
	GTFileStatusTypeChangedInWorktree = GIT_STATUS_WT_TYPECHANGE,
	GTFileStatusRenamedInWorktree     = GIT_STATUS_WT_RENAMED,

	GTFileStatusIgnored = GIT_STATUS_IGNORED,
} GTFileStatusFlags;

// An `NSNumber` wrapped `GTRepositoryStatusOptionsShow` bitmask.
//
// For extending the reporting of status. Using the flags documented below this
// decides what files are sent when enumerating the status.
extern NSString *const GTRepositoryStatusOptionsShowKey;

// An enum, for use as documented, with the `GTRepositoryStatusOptionsShowKey`
// key.
//
// See status.h for documentation of each individual flag.
typedef enum {
	GTRepositoryStatusOptionsShowIndexAndWorkingDirectory = GIT_STATUS_SHOW_INDEX_AND_WORKDIR,
	GTRepositoryStatusOptionsShowIndexOnly = GIT_STATUS_SHOW_INDEX_ONLY,
	GTRepositoryStatusOptionsShowWorkingDirectoryOnly = GIT_STATUS_SHOW_WORKDIR_ONLY,
} GTRepositoryStatusOptionsShow;

// An `NSNumber` wrapped `GTRepositoryStatusOptionsFlags` bitmask containing any
// of the flags documented below.
extern NSString *const GTRepositoryStatusOptionsFlagsKey;

// An enum, for use as documented, with the `GTRepositoryStatusOptionsFlagsKey`
// key.
//
// See status.h for documentation of each individual flag.
typedef enum {
	GTRepositoryStatusFlagsIncludeUntracked = GIT_STATUS_OPT_INCLUDE_UNTRACKED,
	GTRepositoryStatusFlagsIncludeIgnored = GIT_STATUS_OPT_INCLUDE_IGNORED,
	GTRepositoryStatusFlagsIncludeUnmodified = GIT_STATUS_OPT_INCLUDE_UNMODIFIED,
	GTRepositoryStatusFlagsExcludeSubmodules = GIT_STATUS_OPT_EXCLUDE_SUBMODULES,
	GTRepositoryStatusFlagsRecurseUntrackedDirectories = GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS,
	GTRepositoryStatusFlagsDisablePathspecMatch = GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH,
	GTRepositoryStatusFlagsRecurseIgnoredDirectories = GIT_STATUS_OPT_RECURSE_IGNORED_DIRS,
	GTRepositoryStatusFlagsRenamesHeadToIndex = GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX,
	GTRepositoryStatusFlagsRenamesIndexToWorkingDirectory = GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR,
	GTRepositoryStatusFlagsRenamesFromRewrites = GIT_STATUS_OPT_RENAMES_FROM_REWRITES,
	GTRepositoryStatusFlagsSortCaseSensitively = GIT_STATUS_OPT_SORT_CASE_SENSITIVELY,
	GTRepositoryStatusFlagsSortCaseInsensitively = GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY,
} GTRepositoryStatusFlags;

// An `NSArray` of `NSStrings`s to limit the status to specific paths inside the
// repository.  The entries in the array represent either single paths or
// filename patterns with wildcard matching a la standard shell glob (see
// http://linux.die.net/man/7/glob for wildcard matching rules).
//
// Defaults to including all files.
extern NSString *const GTRepositoryStatusOptionsPathSpecArrayKey;

@interface GTRepository (Status)

// `YES` if the working directory has no modified, new, or deleted files.
@property (nonatomic, readonly, getter = isWorkingDirectoryClean) BOOL workingDirectoryClean;

// For each file in the repository, calls your block with the URL of the file
// and the status of that file in the repository.
//
// This will show all file statuses unless a pathspec is specified in the
// options dictionary (using the `GTRepositoryStatusOptionsPathSpecArrayKey`
// key).
//
// options                 - A dictionary of options using the constants above
//                           for keys. If no flags are passed in using
//                           `GTRepositoryStatusOptionsFlagsKey` the defaults of
//                           GTRepositoryStatusOptionsFlagsIncludeIgnored,
//                           GTRepositoryStatusOptionsFlagsIncludeUntracked and
//                           GTRepositoryStatusOptionsFlagsRecurseUntrackedDirectories
//                           are used.
// error                   - Will optionally be set in the event of a failure.
// block                   - The block that gets called for each file.
//                           `headToIndex` is the delta between the HEAD and
//                           index. `indexToWorkingDirectory` is the same but
//                           between the index and the working directory. If
//                           `stop` is set to `YES`, the iteration will cease
//                           after the current step.
//                           Must not be nil.
//
// Returns `NO` in case of a failure or `YES` if the enumeration completed
// successfully.
- (BOOL)enumerateFileStatusWithOptions:(NSDictionary *)options error:(NSError **)error usingBlock:(void (^)(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop))block;

// Query the status of one file
- (GTFileStatusFlags)statusForFile:(NSString *)filePath success:(BOOL *)success error:(NSError **)error;

// Should the file be considered as ignored ?
- (BOOL)shouldFileBeIgnored:(NSURL *)fileURL success:(BOOL *)success error:(NSError **)error;

@end
