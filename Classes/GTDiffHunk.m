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
@property (nonatomic, strong) NSArray *hunkLines;

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

- (void)buildLineArrayWithBlock:(void (^)(GTDiffLine *line, BOOL *stop))block {
	NSMutableArray *hunkLines = [NSMutableArray arrayWithCapacity:self.lineCount];

	for (NSUInteger idx = 0; idx < self.lineCount; idx ++) {
		const git_diff_line *gitLine;
		int result = git_patch_get_line_in_hunk(&gitLine, self.patch.git_patch, self.hunkIndex, idx);
		// FIXME: Report error ?
		if (result != GIT_OK) continue;

		GTDiffLine *line = [[GTDiffLine alloc] initWithGitLine:gitLine];
		[hunkLines addObject:line];

		if (block == nil) continue;

		BOOL stop = NO;
		block(line, &stop);
		if (stop) return;
	}
	self.hunkLines = hunkLines;
}

- (void)enumerateLinesInHunkUsingBlock:(void (^)(GTDiffLine *line, BOOL *stop))block {
	NSParameterAssert(block != nil);

	if (self.hunkLines == nil) {
		[self buildLineArrayWithBlock:block];
		return;
	}
	[self.hunkLines enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		block(obj, stop);
	}];
}

@end
