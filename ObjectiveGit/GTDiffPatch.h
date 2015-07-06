//
//  GTDiffPatch.h
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2014-02-27.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/patch.h"

@class GTDiffHunk;
@class GTDiffDelta;

NS_ASSUME_NONNULL_BEGIN

/// Represents one or more text changes to a single file within a diff.
@interface GTDiffPatch : NSObject

/// The delta corresponding to this patch.
@property (nonatomic, strong, readonly) GTDiffDelta *delta;

/// The number of added lines in this patch.
@property (nonatomic, assign, readonly) NSUInteger addedLinesCount;

/// The number of deleted lines in this patch.
@property (nonatomic, assign, readonly) NSUInteger deletedLinesCount;

/// The number of context lines in this patch.
@property (nonatomic, assign, readonly) NSUInteger contextLinesCount;

/// The number of hunks in this patch.
@property (nonatomic, readonly) NSUInteger hunkCount;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver to wrap the given patch. Designated initializer.
///
/// patch - The patch object to wrap and take ownership of. This will
///         automatically be freed when the receiver is deallocated. Must not be
///         NULL.
/// delta - The diff delta corresponding to this patch. Must not be nil.
- (nullable instancetype)initWithGitPatch:(git_patch *)patch delta:(GTDiffDelta *)delta NS_DESIGNATED_INITIALIZER;

/// Returns the underlying patch object.
- (git_patch *)git_patch __attribute__((objc_returns_inner_pointer));

/// Get the size of this patch.
///
/// includeContext     - Whether to include the context lines in the size.
/// includeHunkHeaders - Whether to include the hunk header lines in the size.
/// includeFileHeaders - Whether to include the file header lines in the size.
///
/// Returns the raw size of the delta, in bytes.
- (NSUInteger)sizeWithContext:(BOOL)includeContext hunkHeaders:(BOOL)includeHunkHeaders fileHeaders:(BOOL)includeFileHeaders;

/// Returns the raw patch data.
- (NSData *)patchData;

/// Enumerate the hunks contained in the patch.
///
/// This enumeration is synchronous, and will block the calling thread while
/// generating hunk content.
///
/// block - A block to be executed for each hunk. Setting `stop` to `YES`
///         will stop the enumeration after the block returns. May not be nil.
///
/// Returns whether enumeration was successful, or terminated early. If `NO`, an
/// error occurred during enumeration.
- (BOOL)enumerateHunksUsingBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
