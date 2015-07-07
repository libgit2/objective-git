//
//  GTDiffPatch.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2014-02-27.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTDiffPatch.h"

#import "GTDiffHunk.h"

@interface GTDiffPatch ()

@property (nonatomic, assign, readonly) git_patch *git_patch;

@end

@implementation GTDiffPatch

#pragma mark Lifecycle

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

- (instancetype)initWithGitPatch:(git_patch *)patch delta:(GTDiffDelta *)delta {
	NSParameterAssert(patch != NULL);
	NSParameterAssert(delta != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_patch = patch;
	_delta = delta;

	size_t adds = 0;
	size_t deletes = 0;
	size_t contexts = 0;
	git_patch_line_stats(&contexts, &adds, &deletes, _git_patch);

	_addedLinesCount = adds;
	_deletedLinesCount = deletes;
	_contextLinesCount = contexts;

	return self;
}

- (void)dealloc {
	if (_git_patch != NULL) {
		git_patch_free(_git_patch);
		_git_patch = NULL;
	}
}

#pragma mark Patch Information

- (NSUInteger)hunkCount {
	return git_patch_num_hunks(self.git_patch);
}

- (NSUInteger)sizeWithContext:(BOOL)includeContext hunkHeaders:(BOOL)includeHunkHeaders fileHeaders:(BOOL)includeFileHeaders {
	return git_patch_size(self.git_patch, includeContext, includeHunkHeaders, includeFileHeaders);
}

- (NSData *)patchData {
	git_buf buf = GIT_BUF_INIT_CONST(0, NULL);
	git_patch_to_buf(&buf, self.git_patch);

	NSData *buffer = [[NSData alloc] initWithBytes:buf.ptr length:buf.size];
	git_buf_free(&buf);
	
	return buffer;
}

#pragma mark Hunks

- (BOOL)enumerateHunksUsingBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block {
	NSParameterAssert(block != nil);

	for (NSUInteger idx = 0; idx < self.hunkCount; idx ++) {
		GTDiffHunk *hunk = [[GTDiffHunk alloc] initWithPatch:self hunkIndex:idx];
		if (hunk == nil) return NO;

		BOOL shouldStop = NO;
		block(hunk, &shouldStop);
		if (shouldStop) break;
	}

	return YES;
}

@end
