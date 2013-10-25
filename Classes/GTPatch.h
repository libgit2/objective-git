//
//  GTPatch.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 24/10/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "git2.h"

@class GTDiffDelta;
@class GTDiffHunk;

@interface GTPatch : NSObject

@property (nonatomic, readonly) GTDiffDelta *delta;

// The number of hunks represented by this patch.
@property (nonatomic, readonly) NSUInteger hunkCount;

// The number of added lines in this patch.
//
// Undefined if this delta is binary.
@property (nonatomic, readonly) NSUInteger addedLinesCount;

// The number of deleted lines in this patch.
//
// Undefined if this delta is binary.
@property (nonatomic, readonly) NSUInteger deletedLinesCount;

// The number of context lines in this patch.
//
// Undefined if this delta is binary.
@property (nonatomic, readonly) NSUInteger contextLinesCount;

// Designated initializer
- (instancetype)initWithGitPatch:(git_patch *)patch inDelta:(GTDiffDelta *)delta;

// The underlying git_patch object
- (git_patch *)git_patch __attribute__((objc_returns_inner_pointer));

// Get the patch size.
//
// includeContext     - Include the context lines in the size. Defaults to NO.
// includeHunkHeaders - Include the hunk header lines in the size. Defaults to NO.
// includeFileHeaders - Include the file header lines in the size. Defaults to NO.
//
// Returns the raw size in bytes of the patch.
- (NSUInteger)sizeWithContext:(BOOL)includeContext hunkHeaders:(BOOL)includeHunkHeaders fileHeaders:(BOOL)includeFileHeaders;

// Enumerate the hunks contained in the patch.
//
// Blocks during enumeration.
//
// block - A block to be executed for each hunk. Setting `stop` to `YES`
//         immediately stops the enumeration.
- (void)enumerateHunksWithBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block;

@end
