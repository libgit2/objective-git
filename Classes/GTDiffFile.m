//
//  GTDiffFile.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffFile.h"

@implementation GTDiffFile

- (instancetype)initWithGitDiffFile:(git_diff_file)file {
	self = [super init];
	if (self == nil) return nil;
	
	_size = (NSUInteger)file.size;
	_flags = (GTDiffFileFlag)file.flags;
	_mode = file.mode;
	_path = [NSString stringWithUTF8String:file.path];
	
	return self;
}

@end
