//
//  GTRepository+Status.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

typedef enum {
	GTRepositoryStatusOptionsShowIndexAndWorkingDirectory = GIT_STATUS_SHOW_INDEX_AND_WORKDIR,
	GTRepositoryStatusOptionsShowIndexOnly = GIT_STATUS_SHOW_INDEX_ONLY,
	GTRepositoryStatusOptionsShowWorkingDirectoryOnly = GIT_STATUS_SHOW_WORKDIR_ONLY,
	GTRepositoryStatusOptionsShowIndexThenWorkingDirectory = GIT_STATUS_SHOW_INDEX_THEN_WORKDIR,
} GTRepositoryStatusOptionsShow;

extern NSString *const GTRepositoryStatusOptionsShowKey;

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

extern NSString *const GTRepositoryStatusOptionsFlagsKey;

extern NSString *const GTRepositoryStatusOptionsPathSpecArrayKey;

typedef void (^GTRepositoryStatusBlock)(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop);

@interface GTRepository (Status)

// For each file in the repository calls your block with the URL of the file and the status of that file in the repository,
//
// block - the block that gets called for each file
- (void)enumerateFileStatusWithOptios:(NSDictionary *)options usingBlock:(GTRepositoryStatusBlock)block;

// Return YES if the working directory is clean (no modified, new, or deleted files in index)
- (BOOL)isWorkingDirectoryClean;

@end
