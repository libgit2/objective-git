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
// GTDiffFileDeltaTypeChange - LOL NO IDEA
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
} GTDiffDeltaType;

// A class representing a single change within a diff.
//
// The change may not be simply a change of text within a given file, it could
// be that the file was renamed, or added to the index. See `GTDiffDeltaType`
// for the types of change represented.
@interface GTDiffDelta : NSObject

// A convenience accessor to fetch the `git_diff_delta` represented by the
// object.
@property (nonatomic, readonly) git_diff_delta *git_diff_delta;

// The backing libgit2 `git_diff_patch` object.
@property (nonatomic, readonly) git_diff_patch *git_diff_patch;

@property (nonatomic, readonly, getter = isBinary) BOOL binary;
@property (nonatomic, readonly, strong) GTDiffFile *oldFile;
@property (nonatomic, readonly, strong) GTDiffFile *newFile;
@property (nonatomic, readonly) GTDiffDeltaType status;
@property (nonatomic, readonly) NSUInteger hunkCount;
@property (nonatomic, readonly, strong) NSArray *hunks;

- (instancetype)initWithGitPatch:(git_diff_patch *)patch;

@end
