//
//  GTDiffDelta.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffDelta.h"

#import "GTDiffFile.h"
#import "GTDiffHunk.h"

@implementation GTDiffDelta

- (instancetype)initWithGitPatch:(git_diff_patch *)patch {
	NSParameterAssert(patch != NULL);
	
	self = [super init];
	if (self == nil) return nil;
	
	_git_diff_patch = patch;
	
	return self;
}

- (void)dealloc {
	git_diff_patch_free(self.git_diff_patch);
}

#pragma mark - Properties

- (const git_diff_delta *)git_diff_delta {
	return git_diff_patch_delta(self.git_diff_patch);
}

- (BOOL)isBinary {
	return (BOOL)self.git_diff_delta->binary;
}

- (GTDiffFile *)oldFile {
	return [[GTDiffFile alloc] initWithGitDiffFile:self.git_diff_delta->old_file];
}

- (GTDiffFile *)newFile {
	return [[GTDiffFile alloc] initWithGitDiffFile:self.git_diff_delta->new_file];
}

- (GTDiffDeltaType)type {
	return (GTDiffDeltaType)self.git_diff_delta->status;
}

- (NSUInteger)hunkCount {
	return git_diff_patch_num_hunks(self.git_diff_patch);
}

- (void)enumerateHunksWithBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block {
	NSParameterAssert(block != nil);
	
	for (NSUInteger idx = 0; idx < self.hunkCount; idx ++) {
		GTDiffHunk *hunk = [[GTDiffHunk alloc] initWithDelta:self hunkIndex:idx];
		if (hunk == nil) return;
		BOOL shouldStop = NO;
		block(hunk, &shouldStop);
		if (shouldStop) return;
	}
}

@end
