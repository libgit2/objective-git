//
//  GTDiffDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"
#import "GTDiffFile.h"

@class GTBlob;
@class GTDiff;
@class GTDiffHunk;
@class GTDiffPatch;

/// The type of change that this delta represents.
///
/// GTDiffFileDeltaUnmodified - No Change.
/// GTDiffFileDeltaAdded      - The file was added to the index.
/// GTDiffFileDeltaDeleted    - The file was removed from the working directory.
/// GTDiffFileDeltaModified   - The file was modified.
/// GTDiffFileDeltaRenamed    - The file has been renamed.
/// GTDiffFileDeltaCopied     - The file was duplicated.
/// GTDiffFileDeltaIgnored    - The file was ignored by git.
/// GTDiffFileDeltaUntracked  - The file has been added to the working directory
///                             and is therefore currently untracked.
/// GTDiffFileDeltaTypeChange - The file has changed from a blob to either a
///                             submodule, symlink or directory. Or vice versa.
typedef NS_ENUM(NSInteger, GTDiffDeltaType) {
	GTDiffFileDeltaUnmodified = GIT_DELTA_UNMODIFIED,
	GTDiffFileDeltaAdded = GIT_DELTA_ADDED,
	GTDiffFileDeltaDeleted = GIT_DELTA_DELETED,
	GTDiffFileDeltaModified = GIT_DELTA_MODIFIED,
	GTDiffFileDeltaRenamed = GIT_DELTA_RENAMED,
	GTDiffFileDeltaCopied = GIT_DELTA_COPIED,
	GTDiffFileDeltaIgnored = GIT_DELTA_IGNORED,
	GTDiffFileDeltaUntracked = GIT_DELTA_UNTRACKED,
	GTDiffFileDeltaTypeChange = GIT_DELTA_TYPECHANGE,
};

/// A class representing a single change within a diff.
///
/// The change may not be simply a change of text within a given file, it could
/// be that the file was renamed, or added to the index. See `GTDiffDeltaType`
/// for the types of change represented.
@interface GTDiffDelta : NSObject

/// The `git_diff_delta` represented by the receiver.
@property (nonatomic, assign, readonly) git_diff_delta git_diff_delta;

/// Any flags set on the delta. See `GTDiffFileFlag` for more info.
///
/// Note that this may not include `GTDiffFileFlagBinary` _or_
/// `GTDiffFileFlagNotBinary` until the content is loaded for this delta (e.g.,
/// through a call to -generatePatch:).
@property (nonatomic, assign, readonly) GTDiffFileFlag flags;

/// The file to the "left" of the diff.
@property (nonatomic, readonly, copy) GTDiffFile *oldFile;

/// The file to the "right" of the diff.
@property (nonatomic, readonly, copy) GTDiffFile *newFile __attribute__((ns_returns_not_retained));

/// The type of change that this delta represents.
///
/// Think "status" as in `git status`.
@property (nonatomic, readonly) GTDiffDeltaType type;

/// Diffs the given blob and data buffer.
///
/// oldBlob     - The blob which should comprise the left side of the diff. May be
///               nil to represent an empty blob.
/// oldBlobPath - The path to which `oldBlob` corresponds. May be nil.
/// newBlob     - The blob which should comprise the right side of the diff. May be
///               nil to represent an empty blob.
/// newBlobPath - The path to which `newBlob` corresponds. May be nil.
/// options     - A dictionary containing any of the above options key constants,
//                or nil to use the defaults.
/// error       - If not NULL, set to any error that occurs.
///
/// Returns a diff delta, or nil if an error occurs.
+ (instancetype)diffDeltaFromBlob:(GTBlob *)oldBlob forPath:(NSString *)oldBlobPath toBlob:(GTBlob *)newBlob forPath:(NSString *)newBlobPath options:(NSDictionary *)options error:(NSError **)error;

/// Diffs the given blob and data buffer.
///
/// blob     - The blob which should comprise the left side of the diff. May be
///            nil to represent an empty blob.
/// blobPath - The path to which `blob` corresponds. May be nil.
/// data     - The data which should comprise the right side of the diff. May be
///            nil to represent an empty blob.
/// dataPath - The path to which `data` corresponds. May be nil.
/// options  - A dictionary containing any of the above options key constants,
//             or nil to use the defaults.
/// error    - If not NULL, set to any error that occurs.
///
/// Returns a diff delta, or nil if an error occurs.
+ (instancetype)diffDeltaFromBlob:(GTBlob *)blob forPath:(NSString *)blobPath toData:(NSData *)data forPath:(NSString *)dataPath options:(NSDictionary *)options error:(NSError **)error;

/// Diffs the given data buffers.
///
/// oldData     - The data which should comprise the left side of the diff. May be
///               nil to represent an empty blob.
/// oldDataPath - The path to which `oldData` corresponds. May be nil.
/// newData     - The data which should comprise the right side of the diff. May
///               be nil to represent an empty blob.
/// newDataPath - The path to which `newData` corresponds. May be nil.
/// options     - A dictionary containing any of the above options key constants,
//                or nil to use the defaults.
/// error       - If not NULL, set to any error that occurs.
///
/// Returns a diff delta, or nil if an error occurs.
+ (instancetype)diffDeltaFromData:(NSData *)oldData forPath:(NSString *)oldDataPath toData:(NSData *)newData forPath:(NSString *)newDataPath options:(NSDictionary *)options error:(NSError **)error;

/// Initializes the receiver to wrap the delta at the given index.
- (instancetype)initWithDiff:(GTDiff *)diff deltaIndex:(NSUInteger)deltaIndex;

/// Creates a patch from a text delta.
///
/// If the receiver represents a binary delta, this method will return an error.
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns a new patch, or nil if an error occurs.
- (GTDiffPatch *)generatePatch:(NSError **)error;

@end
