//
//  GTDiffDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@class GTDiffHunk;

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
} GTDiffDeltaType;

@class GTDiffFile;

@interface GTDiffDelta : NSObject

@property (nonatomic, readonly) git_diff_delta *git_diff_delta;
@property (nonatomic, readonly) git_diff_patch *git_diff_patch;

@property (nonatomic, readonly, getter = isBinary) BOOL binary;
@property (nonatomic, readonly, strong) GTDiffFile *oldFile;
@property (nonatomic, readonly, strong) GTDiffFile *newFile;
@property (nonatomic, readonly) GTDiffDeltaType status;
@property (nonatomic, readonly) NSUInteger hunkCount;
@property (nonatomic, readonly, strong) NSArray *hunks;

- (instancetype)initWithGitPatch:(git_diff_patch *)patch;

@end
