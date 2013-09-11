//
//  GTRepository+Status.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

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
	GTRepositoryStatusOptionsFlagsIncludeUntracked = GIT_STATUS_OPT_INCLUDE_UNTRACKED,
	GTRepositoryStatusOptionsFlagsIncludeIgnored = GIT_STATUS_OPT_INCLUDE_IGNORED,
	GTRepositoryStatusOptionsFlagsIncludeUnmodified = GIT_STATUS_OPT_INCLUDE_UNMODIFIED,
	GTRepositoryStatusOptionsFlagsExcludeSubmodules = GIT_STATUS_OPT_EXCLUDE_SUBMODULES,
	GTRepositoryStatusOptionsFlagsRecurseUntrackedDirectories = GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS,
	GTRepositoryStatusOptionsFlagsDisablePathspecMatch = GIT_STATUS_OPT_DISABLE_PATHSPEC_MATCH,
	GTRepositoryStatusOptionsFlagsRecurseIgnoredDirectories = GIT_STATUS_OPT_RECURSE_IGNORED_DIRS,
	GTRepositoryStatusOptionsFlagsRenamesHeadToIndex = GIT_STATUS_OPT_RENAMES_HEAD_TO_INDEX,
	GTRepositoryStatusOptionsFlagsRenamesIndexToWorkingDirectory = GIT_STATUS_OPT_RENAMES_INDEX_TO_WORKDIR,
	GTRepositoryStatusOptionsFlagsSortCaseSensitively = GIT_STATUS_OPT_SORT_CASE_SENSITIVELY,
	GTRepositoryStatusOptionsFlagsSortCaseInsensitively = GIT_STATUS_OPT_SORT_CASE_INSENSITIVELY,
} GTRepositoryStatusOptionsFlags;

// An `NSArray` of `NSStrings`s to limit the status to specific paths inside the
// repository.  The entries in the array represent either single paths or
// filename patterns with wildcard matching a la standard shell glob (see
// http://linux.die.net/man/7/glob for wildcard matching rules).
//
// Defaults to including all files.
extern NSString *const GTRepositoryStatusOptionsPathSpecArrayKey;

@interface GTRepository (Status)

// Return YES if the working directory is clean (no modified, new, or deleted files in index)
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
// block                   - the block that gets called for each file.
//                           `headToIndex` is the delta between the HEAD and
//                           index. `indexToWorkingDirectory` is the same but
//                           between the index and the working directory. If
//                           `stop` is set to `YES`, the iteration will cease.
//
// Returns `NO` in case of a failure or `YES` if the enumeration could be
// completed successfully
- (BOOL)enumerateFileStatusWithOptions:(NSDictionary *)options error:(NSError **)error usingBlock:(void(^)(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop))block;

@end
