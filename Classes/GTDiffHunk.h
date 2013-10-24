//
//  GTDiffHunk.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@class GTDiffDelta;
@class GTDiffLine;
@class GTPatch;

// A class representing a hunk within a diff delta.
@interface GTDiffHunk : NSObject

// The header of the hunk.
@property (nonatomic, readonly, copy) NSString *header;

// The number of lines represented in the hunk.
@property (nonatomic, readonly) NSUInteger lineCount;

// Designated initialiser.
- (instancetype)initWithGitHunk:(const git_diff_hunk *)hunk hunkIndex:(NSUInteger)hunkIndex patch:(GTPatch *)patch;

// Perfoms the given block on each line in the hunk.
//
// Note that this method blocks during the enumeration.
//
// block - A block to execute on each line. Setting `stop` to `NO` will
//         immediately stop the enumeration and return from the method.
- (void)enumerateLinesInHunkUsingBlock:(void (^)(GTDiffLine *line, BOOL *stop))block;

@end
