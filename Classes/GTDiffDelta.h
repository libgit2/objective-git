//
//  GTDiffDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"
#import "GTDiffFile.h"

@class GTDiff;
@class GTDiffHunk;
@class GTDiffPatch;

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

// The `git_diff_delta` represented by the receiver.
@property (nonatomic, assign, readonly) git_diff_delta git_diff_delta;

// The diff in which this delta is contained.
@property (nonatomic, strong, readonly) GTDiff *diff;

// Any flags set on the delta. See `GTDiffFileFlag` for more info.
//
// Note that this may not include `GTDiffFileFlagBinary` _or_
// `GTDiffFileFlagNotBinary` until the content is loaded for this delta (e.g.,
// through a call to -generatePatch:).
@property (nonatomic, assign, readonly) GTDiffFileFlag flags;

// The file to the "left" of the diff.
@property (nonatomic, readonly, copy) GTDiffFile *oldFile;

// The file to the "right" of the diff.
@property (nonatomic, readonly, copy) GTDiffFile *newFile __attribute__((ns_returns_not_retained));

// The type of change that this delta represents.
//
// Think "status" as in `git status`.
@property (nonatomic, readonly) GTDiffDeltaType type;

// Initializes the receiver to wrap the delta at the given index.
- (instancetype)initWithDiff:(GTDiff *)diff deltaIndex:(NSUInteger)deltaIndex;

// Creates a patch from a text delta.
//
// If the receiver represents a binary delta, this method will return an error.
//
// error - If not NULL, set to any error that occurs.
//
// Returns a new patch, or nil if an error occurs.
- (GTDiffPatch *)generatePatch:(NSError **)error;

@end
