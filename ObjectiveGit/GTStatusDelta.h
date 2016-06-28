//
//  GTStatusDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/diff.h"
#import <ObjectiveGit/GTDiffDelta.h>

@class GTDiffFile;

NS_ASSUME_NONNULL_BEGIN

/// Represents the status of a file in a repository.
@interface GTStatusDelta : NSObject

/// The file as it was prior to the change represented by this status delta.
@property (nonatomic, readonly, copy) GTDiffFile * _Nullable oldFile;

/// The file after the change represented by this status delta
@property (nonatomic, readonly, copy) GTDiffFile * _Nullable newFile __attribute__((ns_returns_not_retained));

/// The status of the file.
@property (nonatomic, readonly) GTDeltaType status;

/// A float between 0 and 1 describing how similar the old and new
/// files are (where 0 is not at all and 1 is identical).
///
/// Only useful when the status is `GTStatusDeltaStatusRenamed` or
/// `GTStatusDeltaStatusCopied`.
@property (nonatomic, readonly) double similarity;

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer.
- (instancetype _Nullable)initWithGitDiffDelta:(const git_diff_delta *)delta NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
