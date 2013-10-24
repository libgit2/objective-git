//
//  GTDiffHunk.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffHunk.h"

#import "GTDiffDelta.h"
#import "GTDiffLine.h"
#import "GTPatch.h"

@interface GTDiffHunk ()

@property (nonatomic, assign, readonly) const git_diff_hunk *hunk;
@property (nonatomic, strong, readonly) GTPatch *patch;
@property (nonatomic, assign, readonly) NSUInteger hunkIndex;

@end

@implementation GTDiffHunk

- (instancetype)initWithGitHunk:(const git_diff_hunk *)hunk hunkIndex:(NSUInteger)hunkIndex patch:(GTPatch *)patch {
	self = [super init];
	if (self == nil) return nil;
	
	_patch = patch;
	_hunk = hunk;
	_hunkIndex = hunkIndex;

	return self;
}

- (NSUInteger)lineCount {
	return git_patch_num_lines_in_hunk(self.patch.git_patch, self.hunkIndex);
}

- (void)enumerateLinesInHunkUsingBlock:(void (^)(GTDiffLine *line, BOOL *stop))block {
	NSParameterAssert(block != nil);

	for (NSUInteger idx = 0; idx < self.lineCount; idx ++) {
		const git_diff_line *gitLine;
		int result = git_patch_get_line_in_hunk(&gitLine, self.patch.git_patch, self.hunkIndex, idx);
		if (result != GIT_OK) continue;

		// TODO: Cache line
		GTDiffLine *line = [[GTDiffLine alloc] initWithGitLine:gitLine];

		BOOL stop = NO;
		block(line, &stop);
		if (stop) return;
	}
}

@end
