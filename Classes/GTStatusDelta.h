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

@interface GTStatusDelta : NSObject

@property (nonatomic, readonly, copy) GTDiffFile *oldFile;

@property (nonatomic, readonly, copy) GTDiffFile *newFile;

@property (nonatomic, readonly) GTStatusDeltaStatus status;

@property (nonatomic, readonly) NSUInteger similarity;

@end
