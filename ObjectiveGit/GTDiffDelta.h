//
//  GTDiffDelta.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/diff.h"
#import "GTDiffFile.h"

@class GTBlob;
@class GTDiff;
@class GTDiffHunk;
@class GTDiffPatch;

/// The type of change that this delta represents.
///
/// GTDeltaTypeUnmodified - No Change.
/// GTDeltaTypeAdded      - The file was added to the index.
/// GTDeltaTypeDeleted    - The file was removed from the working directory.
/// GTDeltaTypeModified   - The file was modified.
/// GTDeltaTypeRenamed    - The file has been renamed.
/// GTDeltaTypeCopied     - The file was duplicated.
/// GTDeltaTypeIgnored    - The file was ignored by git.
/// GTDeltaTypeUntracked  - The file has been added to the working directory
///                             and is therefore currently untracked.
/// GTDeltaTypeTypeChange - The file has changed from a blob to either a
///                             submodule, symlink or directory. Or vice versa.
/// GTDeltaTypeConflicted - The file is conflicted in the working directory.
typedef NS_ENUM(NSInteger, GTDeltaType) {
	GTDeltaTypeUnmodified = GIT_DELTA_UNMODIFIED,
	GTDeltaTypeAdded = GIT_DELTA_ADDED,
	GTDeltaTypeDeleted = GIT_DELTA_DELETED,
	GTDeltaTypeModified = GIT_DELTA_MODIFIED,
	GTDeltaTypeRenamed = GIT_DELTA_RENAMED,
	GTDeltaTypeCopied = GIT_DELTA_COPIED,
	GTDeltaTypeIgnored = GIT_DELTA_IGNORED,
	GTDeltaTypeUntracked = GIT_DELTA_UNTRACKED,
	GTDeltaTypeTypeChange = GIT_DELTA_TYPECHANGE,
	GTDeltaTypeUnreadable = GIT_DELTA_UNREADABLE,
	GTDeltaTypeConflicted = GIT_DELTA_CONFLICTED,
};

NS_ASSUME_NONNULL_BEGIN

/// A class representing a single change within a diff.
///
/// The change may not be simply a change of text within a given file, it could
/// be that the file was renamed, or added to the index. See `GTDeltaType`
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
@property (nonatomic, readonly) GTDeltaType type;

@property (nonatomic, readonly, assign) double similarity;

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
+ (instancetype _Nullable)diffDeltaFromBlob:(GTBlob * _Nullable)oldBlob forPath:(NSString * _Nullable)oldBlobPath toBlob:(GTBlob * _Nullable)newBlob forPath:(NSString * _Nullable)newBlobPath options:(NSDictionary * _Nullable)options error:(NSError **)error;

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
+ (instancetype _Nullable)diffDeltaFromBlob:(GTBlob * _Nullable)blob forPath:(NSString * _Nullable)blobPath toData:(NSData * _Nullable)data forPath:(NSString * _Nullable)dataPath options:(NSDictionary * _Nullable)options error:(NSError **)error;

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
+ (instancetype _Nullable)diffDeltaFromData:(NSData * _Nullable)oldData forPath:(NSString * _Nullable)oldDataPath toData:(NSData * _Nullable)newData forPath:(NSString * _Nullable)newDataPath options:(NSDictionary * _Nullable)options error:(NSError **)error;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver to wrap the delta at the given index.
///
/// diff       - The diff which contains the delta to wrap. Must not be nil.
/// deltaIndex - The index of the delta within the diff.
///
/// Returns a diff delta, or nil if an error occurs.
- (instancetype _Nullable)initWithDiff:(GTDiff *)diff deltaIndex:(NSUInteger)deltaIndex;

/// Creates a patch from a text delta.
///
/// If the receiver represents a binary delta, this method will return an error.
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns a new patch, or nil if an error occurs.
- (GTDiffPatch * _Nullable)generatePatch:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
