//
//  GTDiff.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 29/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@class GTDiffFile;
@class GTTree;

typedef enum : git_delta_t {
	GTDiffFileDeltaUnmodified = GIT_DELTA_UNMODIFIED,
	GTDiffFileDeltaAdded = GIT_DELTA_ADDED,
	GTDiffFileDeltaDeleted = GIT_DELTA_DELETED,
	GTDiffFileDeltaModified = GIT_DELTA_MODIFIED,
	GTDiffFileDeltaRenamed = GIT_DELTA_RENAMED,
	GTDiffFileDeltaCopied = GIT_DELTA_COPIED,
	GTDiffFileDeltaIgnored = GIT_DELTA_IGNORED,
	GTDiffFileDeltaUntracked = GIT_DELTA_UNTRACKED,
	GTDiffFileDeltaTypeChange = GIT_DELTA_TYPECHANGE,
} GTDiffFileDelta;

@interface GTDiff : NSObject

@property (nonatomic, readonly, assign) git_diff_list *git_diff_list;
@property (nonatomic, readonly, strong) NSArray *files;

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree options:(NSUInteger)options;
+ (GTDiff *)diffIndexToOldTree:(GTTree *)oldTree withOptions:(NSUInteger)options;
+ (GTDiff *)diffWorkingDirectoryToIndexWithOptions:(NSUInteger)options;
+ (GTDiff *)diffWorkingDirectoryToTree:(GTTree *)tree withOptions:(NSUInteger)options;

- (id)initWithGitDiffList:(git_diff_list *)diffList;

@end
