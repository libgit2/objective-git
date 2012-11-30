//
//  GTDiffHunk.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffHunk.h"

#import "GTDiffDelta.h"

@interface GTDiffHunk ()

@property (nonatomic, unsafe_unretained, readonly) GTDiffDelta *delta; //No weak support in this deployment target? Boo!
@property (nonatomic, readonly) NSUInteger hunkIndex;

@end

@implementation GTDiffHunk

- (instancetype)initWithDelta:(GTDiffDelta *)delta hunkIndex:(NSUInteger)hunkIndex {
	self = [super init];
	if (self == nil) return nil;
	
	_delta = delta;
	_hunkIndex = hunkIndex;
	
	const char *headerCString;
	size_t headerLength;
	size_t lineCount;
	int result = git_diff_patch_get_hunk(NULL, &headerCString, &headerLength, &lineCount, delta.git_diff_patch, hunkIndex);
	if (result != GIT_OK) return nil;
	
	_header = [NSString stringWithCharacters:(const unichar *)headerCString length:headerLength];
	_lineCount = lineCount;

	return self;
}

@end
