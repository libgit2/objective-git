//
//  GTDiffFile.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

typedef enum : git_diff_file_flag_t {
	GTDiffFileFlagValidOID = GIT_DIFF_FILE_VALID_OID,
	GTDiffFileFlagFreePath = GIT_DIFF_FILE_FREE_PATH,
	GTDiffFileFlagBinary = GIT_DIFF_FILE_BINARY,
	GTDiffFileFlagNotBinary = GIT_DIFF_FILE_NOT_BINARY,
	GTDiffFileFlagFreeData = GIT_DIFF_FILE_FREE_DATA,
	GTDiffFileFlagUnmapData = GIT_DIFF_FILE_UNMAP_DATA,
	GTDiffFileFlagNoData = GIT_DIFF_FILE_NO_DATA,
} GTDiffFileFlag;

@interface GTDiffFile : NSObject

@property (nonatomic, readonly, strong) NSString *path;
@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, readonly) NSUInteger flags;
@property (nonatomic, readonly) NSUInteger mode;

- (instancetype)initWithGitDiffFile:(git_diff_file)file;

@end
