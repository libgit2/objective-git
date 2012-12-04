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

extern NSString *const GTDiffOptionsFlagsKey;
extern NSString *const GTDiffOptionsContextLinesKey;
extern NSString *const GTDiffOptionsInterHunkLinesKey;
extern NSString *const GTDiffOptionsOldPrefixKey;
extern NSString *const GTDiffOptionsNewPrefixKey;
extern NSString *const GTDiffOptionsMaxSizeKey;

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

@interface GTDiff : NSObject

@property (nonatomic, readonly) git_diff_list *git_diff_list;
@property (nonatomic, readonly) NSUInteger deltaCount;

//TODO: Need to settle on a method for sending in the options struct

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree withOptions:(NSDictionary *)options;
+ (GTDiff *)diffIndexToTree:(GTTree *)oldTree withOptions:(NSDictionary *)options;
+ (GTDiff *)diffWorkingDirectoryToIndexInRepository:(GTRepository *)repository withOptions:(NSDictionary *)options;
+ (GTDiff *)diffWorkingDirectoryToTree:(GTTree *)tree withOptions:(NSDictionary *)options;

- (instancetype)initWithGitDiffList:(git_diff_list *)diffList;
- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType;
- (void)enumerateDeltasUsingBlock:(BOOL(^)(GTDiffDelta *delta))block;

@end
