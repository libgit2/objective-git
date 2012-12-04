//
//  GTDiff.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 29/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

#import "GTDiffDelta.h"

@class GTDiffDelta;
@class GTRepository;
@class GTTree;

// An `NSNumber` wrapped `GTDiffOptionsFlags` representing any flags you wish to
// pass into the initialisation.
extern NSString *const GTDiffOptionsFlagsKey;

// An `NSNumber` wrapped `NSUInteger` dictating how many context lines above and
// below each individual hunk.
//
// Defaults to 3.
extern NSString *const GTDiffOptionsContextLinesKey;

// An `NSNumber` wrapped `NSUInteger` dictating the minimum number of lines
// between diff hunks to merge them into one hunk.
//
// Defaults to 0.
extern NSString *const GTDiffOptionsInterHunkLinesKey;

// An `NSString` to prefix old file names with.
//
// Defaults to "a".
extern NSString *const GTDiffOptionsOldPrefixKey;

// An `NSString` to prefix new file names with.
//
// Defaults to "b".
extern NSString *const GTDiffOptionsNewPrefixKey;

// An `NSNumber` wrapped `NSUInteger` determining the maximum size (in bytes)
// of a file to diff. Above this size the file will be treated as binary.
//
// Defaults to 512Mb.
extern NSString *const GTDiffOptionsMaxSizeKey;

// Enum for use as documented in the options dictionary with the
// `GTDiffOptionsFlagsKey` key.
//
// See diff.h for documentation of each individual flag. 
typedef enum : git_diff_option_t {
	GTDiffOptionsFlagsNormal = GIT_DIFF_NORMAL,
	GTDiffOptionsFlagsReverse = GIT_DIFF_REVERSE,
	GTDiffOptionsFlagsForceText = GIT_DIFF_FORCE_TEXT,
	GTDiffOptionsFlagsIgnoreWhitespace = GIT_DIFF_IGNORE_WHITESPACE,
	GTDiffOptionsFlagsIgnoreWhitespaceChange = GIT_DIFF_IGNORE_WHITESPACE_CHANGE,
	GTDiffOptionsFlagsIgnoreWhitespaceEOL = GIT_DIFF_IGNORE_WHITESPACE_EOL,
	GTDiffOptionsFlagsIgnoreSubmodules = GIT_DIFF_IGNORE_SUBMODULES,
	GTDiffOptionsFlagsPatience = GIT_DIFF_PATIENCE,
	GTDiffOptionsFlagsIncludeIgnored = GIT_DIFF_INCLUDE_IGNORED,
	GTDiffOptionsFlagsIncludeUntracked = GIT_DIFF_INCLUDE_UNTRACKED,
	GTDiffOptionsFlagsIncludeUnmodified = GIT_DIFF_INCLUDE_UNMODIFIED,
	GTDiffOptionsFlagsRecurseUntrackedDirs = GIT_DIFF_RECURSE_UNTRACKED_DIRS,
	GTDiffOptionsFlagsDisablePathspecMatch = GIT_DIFF_DISABLE_PATHSPEC_MATCH,
	GTDiffOptionsFlagsDeltasAreICase = GIT_DIFF_DELTAS_ARE_ICASE,
	GTDiffOptionsFlagsIncludeUntrackedContent = GIT_DIFF_INCLUDE_UNTRACKED_CONTENT,
	GTDiffOptionsFlagsSkipBinaryCheck = GIT_DIFF_SKIP_BINARY_CHECK,
	GTDiffOptionsFlagsIncludeTypeChange = GIT_DIFF_INCLUDE_TYPECHANGE,
	GTDiffOptionsFlagsIncludeTypeChangeTrees = GIT_DIFF_INCLUDE_TYPECHANGE_TREES,
	GTDiffOptionsFlagsIgnoreFileMode = GIT_DIFF_IGNORE_FILEMODE,
} GTDiffOptionsFlags;

// A class representing a single "diff".
//
// Analagous to `git_diff_list` in libgit2, this object represents a list of
// changes or "deltas", which are represented by `GTDiffDelta` objects.
@interface GTDiff : NSObject

// The libgit2 diff list object.
@property (nonatomic, readonly) git_diff_list *git_diff_list;
@property (nonatomic, readonly) NSUInteger deltaCount;


+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree withOptions:(NSDictionary *)options;
+ (GTDiff *)diffIndexToTree:(GTTree *)oldTree withOptions:(NSDictionary *)options;
+ (GTDiff *)diffWorkingDirectoryToIndexInRepository:(GTRepository *)repository withOptions:(NSDictionary *)options;
+ (GTDiff *)diffWorkingDirectoryToTree:(GTTree *)tree withOptions:(NSDictionary *)options;

- (instancetype)initWithGitDiffList:(git_diff_list *)diffList;
- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType;
- (void)enumerateDeltasUsingBlock:(BOOL(^)(GTDiffDelta *delta))block;

@end
