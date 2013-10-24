//
//  GTPatch.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 24/10/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTPatch.h"
#import "GTDiffHunk.h"

@interface GTPatch ()
@property (nonatomic, assign, readonly) git_patch *git_patch;
//@property (nonatomic, assign, readonly) GTDiffDelta *delta;
@end

@implementation GTPatch

- (instancetype)initWithGitPatch:(git_patch *)patch inDelta:(GTDiffDelta *)delta {
	NSParameterAssert(patch != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_patch = patch;
	_delta = delta;

	size_t adds = 0;
	size_t deletes = 0;
	size_t contexts = 0;
	git_patch_line_stats(&contexts, &adds, &deletes, patch);

	_addedLinesCount = adds;
	_deletedLinesCount = deletes;
	_contextLinesCount = contexts;

	return self;
}

- (void)dealloc {
	if (_git_patch) {
		git_patch_free(_git_patch);
		_git_patch = NULL;
	}
}

- (NSUInteger)hunkCount {
	return git_patch_num_hunks(self.git_patch);
}

- (void)enumerateHunksWithBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block {
	NSParameterAssert(block != nil);

	for (NSUInteger idx = 0; idx < self.hunkCount; idx ++) {
		const git_diff_hunk *gitHunk;
		git_patch_get_hunk(&gitHunk, NULL, self.git_patch, idx);
		// TODO: Cache hunks
		GTDiffHunk *hunk = [[GTDiffHunk alloc] initWithGitHunk:gitHunk hunkIndex:idx patch:self];
		if (hunk == nil) return;

		BOOL shouldStop = NO;
		block(hunk, &shouldStop);
		if (shouldStop) return;
	}
}

@end
