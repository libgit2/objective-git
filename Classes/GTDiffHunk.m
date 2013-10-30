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

@interface GTDiffHunk ()

@property (nonatomic, assign, readonly) const git_diff_hunk *git_hunk;
@property (nonatomic, strong, readonly) GTDiffDelta *delta;
@property (nonatomic, assign, readonly) NSUInteger hunkIndex;
@property (nonatomic, copy) NSString *header;
@property (nonatomic, assign) NSUInteger lineCount;

@end

@implementation GTDiffHunk

- (instancetype)initWithDelta:(GTDiffDelta *)delta hunkIndex:(NSUInteger)hunkIndex {
	self = [super init];
	if (self == nil) return nil;

	int result = git_patch_get_hunk(&_git_hunk, &_lineCount, delta.git_patch, hunkIndex);
	if (result != GIT_OK) return nil;

	_delta = delta;
	_hunkIndex = hunkIndex;
	_header = [[[NSString alloc] initWithBytes:self.git_hunk->header length:self.git_hunk->header_len encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];

	return self;
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ hunkIndex: %ld, header: %@, lineCount: %ld", super.debugDescription, (unsigned long)self.hunkIndex, self.header, (unsigned long)self.lineCount];
}

- (void)enumerateLinesInHunkUsingBlock:(void (^)(GTDiffLine *line, BOOL *stop))block {
	NSParameterAssert(block != nil);

	for (NSUInteger idx = 0; idx < self.lineCount; idx ++) {
		const git_diff_line *gitLine;
		int result = git_patch_get_line_in_hunk(&gitLine, self.delta.git_patch, self.hunkIndex, idx);
		// FIXME: Report error ?
		if (result != GIT_OK) continue;

		GTDiffLine *line = [[GTDiffLine alloc] initWithGitLine:gitLine];

		BOOL stop = NO;
		block(line, &stop);
		if (stop) return;
	}
}

@end
