//
//  GTDiffFile.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@interface GTDiffFile : NSObject

@property (nonatomic, readonly) git_diff_file git_diff_file;

@property (nonatomic, readonly, strong) NSString *path;
@property (nonatomic, readonly) NSUInteger size;

- (instancetype)initWithGitDiffFile:(git_diff_file)file;

@end
