//
//  GTStatusDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "git2.h"

@class GTDiffFile;

// An enum representing the status of the file.
//
// See diff.h for documentation of individual flags.
typedef enum {
	GTStatusDeltaStatusUnmodified = GIT_DELTA_UNMODIFIED,
	GTStatusDeltaStatusAdded = GIT_DELTA_ADDED,
	GTStatusDeltaStatusDeleted = GIT_DELTA_DELETED,
	GTStatusDeltaStatusModified = GIT_DELTA_MODIFIED,
	GTStatusDeltaStatusRenamed = GIT_DELTA_RENAMED,
	GTStatusDeltaStatusCopied = GIT_DELTA_COPIED,
	GTStatusDeltaStatusIgnored = GIT_DELTA_IGNORED,
	GTStatusDeltaStatusUntracked = GIT_DELTA_UNTRACKED,
	GTStatusDeltaStatusTypeChange = GIT_DELTA_TYPECHANGE,
} GTStatusDeltaStatus;

// Represents the status of a file in a repository.
@interface GTStatusDelta : NSObject

// The file as it was prior to the change represented by this status delta.
@property (nonatomic, readonly, copy) GTDiffFile *oldFile;

// The file after the change represented by this status delta
@property (nonatomic, readonly, copy) GTDiffFile *newFile __attribute__((ns_returns_not_retained));

// The status of the file.
@property (nonatomic, readonly) GTStatusDeltaStatus status;

// A float between 0 and 1 describing how similar the old and new
// files are (where 0 is not at all and 1 is identical).
//
// Only useful when the status is `GTStatusDeltaStatusRenamed` or
// `GTStatusDeltaStatusCopied`.
@property (nonatomic, readonly) double similarity;

// Designated initializer.
- (instancetype)initWithGitDiffDelta:(const git_diff_delta *)delta;

@end
