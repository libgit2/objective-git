//
//  GTDiffDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@class GTDiffFile;
@class GTDiffHunk;
@class GTDiff;

// The type of change that this delta represents.
//
// GTDiffFileDeltaUnmodified - No Change.
// GTDiffFileDeltaAdded      - The file was added to the index.
// GTDiffFileDeltaDeleted    - The file was removed from the working directory.
// GTDiffFileDeltaModified   - The file was modified.
// GTDiffFileDeltaRenamed    - The file has been renamed.
// GTDiffFileDeltaCopied     - The file was duplicated.
// GTDiffFileDeltaIgnored    - The file was ignored by git.
// GTDiffFileDeltaUntracked  - The file has been added to the working directory
//                             and is therefore currently untracked.
// GTDiffFileDeltaTypeChange - The file has changed from a blob to either a
//                             submodule, symlink or directory. Or vice versa.
typedef enum {
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

// A class representing a single change within a diff.
//
// The change may not be simply a change of text within a given file, it could
// be that the file was renamed, or added to the index. See `GTDiffDeltaType`
// for the types of change represented.
@interface GTDiffDelta : NSObject

// The backing libgit2 `git_diff` object.
@property (nonatomic, readonly) git_diff *git_diff;

// The underlying libgit2 `git_patch` object.
@property (nonatomic, assign, readonly) git_patch *git_patch;

// Whether the file(s) are to be treated as binary.
@property (nonatomic, readonly, getter = isBinary) BOOL binary;

// The file to the "left" of the diff.
@property (nonatomic, readonly, copy) GTDiffFile *oldFile;

// The file to the "right" of the diff.
@property (nonatomic, readonly, copy) GTDiffFile *newFile __attribute__((ns_returns_not_retained));

// The type of change that this delta represents.
//
// Think "status" as in `git status`.
@property (nonatomic, readonly) GTDiffDeltaType type;

// The number of hunks represented by this delta.
@property (nonatomic, readonly) NSUInteger hunkCount;

// The number of added lines in this delta.
//
// Undefined if this delta is binary.
@property (nonatomic, readonly) NSUInteger addedLinesCount;

// The number of deleted lines in this delta.
//
// Undefined if this delta is binary.
@property (nonatomic, readonly) NSUInteger deletedLinesCount;

// The number of context lines in this delta.
//
// Undefined if this delta is binary.
@property (nonatomic, readonly) NSUInteger contextLinesCount;

// Designated initialiser.
- (instancetype)initWithGitPatch:(git_patch *)patch;

// A convenience accessor to fetch the `git_diff_delta` represented by the
// object.
- (const git_diff_delta *)git_diff_delta __attribute__((objc_returns_inner_pointer));

// Get the delta size.
//
// includeContext     - Include the context lines in the size. Defaults to NO.
// includeHunkHeaders - Include the hunk header lines in the size. Defaults to NO.
// includeFileHeaders - Include the file header lines in the size. Defaults to NO.
//
// Returns the raw size in bytes of the delta.
- (NSUInteger)sizeWithContext:(BOOL)includeContext hunkHeaders:(BOOL)includeHunkHeaders fileHeaders:(BOOL)includeFileHeaders;

// Enumerate the hunks contained in the delta.
//
// Blocks during enumeration.
//
// block - A block to be executed for each hunk. Setting `stop` to `YES`
//         immediately stops the enumeration.
- (void)enumerateHunksUsingBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block;

@end
