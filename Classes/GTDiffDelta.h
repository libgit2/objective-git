//
//  GTDiffDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

#import "GTDiff.h"

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

@class GTDiffFile;

@interface GTDiffDelta : NSObject

@property (nonatomic, readonly) git_diff_delta git_diff_delta;

@property (nonatomic, readonly, strong) NSArray *hunks;
@property (nonatomic, readonly, getter = isBinary) BOOL binary;
@property (nonatomic, readonly, strong) GTDiffFile *oldFile;
@property (nonatomic, readonly, strong) GTDiffFile *newFile;
@property (nonatomic, readonly) GTDiffFileDelta status;

- (id)initWithGitDelta:(git_diff_delta *)delta;

@end
