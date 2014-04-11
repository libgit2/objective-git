//
//  GTDiffFile.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

// Flags which may be set on the file.
//
// GTDiffFileFlagBinaryMask - A mask to just retrieve the binary/not binary
//                            information from a set of flags.
//
// See diff.h for further documentation.
typedef enum {
	GTDiffFileFlagValidID = GIT_DIFF_FLAG_VALID_ID,
	GTDiffFileFlagBinary = GIT_DIFF_FLAG_BINARY,
	GTDiffFileFlagNotBinary = GIT_DIFF_FLAG_NOT_BINARY,

	GTDiffFileFlagBinaryMask = GTDiffFileFlagBinary | GTDiffFileFlagNotBinary,
} GTDiffFileFlag;

@class GTOID;

// A class representing a file on one side of a diff.
@interface GTDiffFile : NSObject

// The location within the working directory of the file.
@property (nonatomic, readonly, copy) NSString *path;

// The size (in bytes) of the file.
@property (nonatomic, readonly) NSUInteger size;

// Any flags set on the file (see `GTDiffFileFlag` for more info).
@property (nonatomic, readonly) GTDiffFileFlag flags;

// The mode of the file.
@property (nonatomic, readonly) mode_t mode;

// The OID for the file.
@property (nonatomic, readonly, copy) GTOID *OID;

// The git_diff_file represented by the receiver.
@property (nonatomic, readonly) git_diff_file git_diff_file;

/// Initializes the receiver with the provided libgit2 object.
///
/// file - The git_diff_file wrapped by the receiver.
///
/// Returns an initialized GTDiffFile.
- (instancetype)initWithGitDiffFile:(git_diff_file)file;

@end
