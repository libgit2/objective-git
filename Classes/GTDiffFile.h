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
typedef enum : git_diff_file_flag_t {
	GTDiffFileFlagValidOID = GIT_DIFF_FILE_VALID_OID,
	GTDiffFileFlagFreePath = GIT_DIFF_FILE_FREE_PATH,
	GTDiffFileFlagBinary = GIT_DIFF_FILE_BINARY,
	GTDiffFileFlagNotBinary = GIT_DIFF_FILE_NOT_BINARY,
	GTDiffFileFlagFreeData = GIT_DIFF_FILE_FREE_DATA,
	GTDiffFileFlagUnmapData = GIT_DIFF_FILE_UNMAP_DATA,
	GTDiffFileFlagNoData = GIT_DIFF_FILE_NO_DATA,
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
