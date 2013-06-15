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
// See diff.h for individual documentation.
typedef enum : int {
	GTDiffFileFlagValidOID = GIT_DIFF_FLAG_VALID_OID,
	GTDiffFileFlagBinary = GIT_DIFF_FLAG_BINARY,
	GTDiffFileFlagNotBinary = GIT_DIFF_FLAG_NOT_BINARY,
} GTDiffFileFlag;

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

// Designated initialiser.
- (instancetype)initWithGitDiffFile:(git_diff_file)file;

@end
