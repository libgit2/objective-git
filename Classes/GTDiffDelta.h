//
//  GTDiffDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

#import "GTDiff.h"

@class GTDiffFile;

@interface GTDiffDelta : NSObject

@property (nonatomic, readonly) git_diff_delta git_diff_delta;

@property (nonatomic, readonly, strong) NSArray *hunks;
@property (nonatomic, readonly, getter = isBinary) BOOL binary;
@property (nonatomic, readonly, strong) GTDiffFile *oldFile;
@property (nonatomic, readonly, strong) GTDiffFile *newFile;
@property (nonatomic, readonly) GTDiffFileDelta status;

@end
