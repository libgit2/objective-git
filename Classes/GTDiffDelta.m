//
//  GTDiffDelta.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffDelta.h"

@implementation GTDiffDelta

- (instancetype)initWithGitPatch:(git_diff_patch *)patch {
	self = [super init];
	if (self == nil) return nil;
	
	_git_diff_patch = patch;
	
	return self;
}

- (void)dealloc
{
	git_diff_patch_free(self.git_diff_patch);
}

@end
