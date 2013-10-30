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
#import "GTDiff.h"

@interface GTDiffDelta ()
@property (nonatomic, strong, readonly) GTDiff *diff;
@property (nonatomic, assign, readonly) NSInteger deltaIndex;
@property (strong) NSArray *patchHunks;
@end

@implementation GTDiffDelta

- (instancetype)initWithGitPatch:(git_patch *)patch {
	NSParameterAssert(patch != NULL);
	
	self = [super init];
	if (self == nil) return nil;

	_git_patch = patch;

	size_t adds = 0;
	size_t deletes = 0;
	size_t contexts = 0;
	git_patch_line_stats(&contexts, &adds, &deletes, _git_patch);

	_addedLinesCount = adds;
	_deletedLinesCount = deletes;
	_contextLinesCount = contexts;

	return self;
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ flags: %u, oldFile: %@, newFile: %@", super.debugDescription, self.git_diff_delta->flags, self.oldFile, self.newFile];
}

- (void)dealloc {
	if (_git_patch) {
		git_patch_free(_git_patch);
		_git_patch = NULL;
	}
}

#pragma mark - Properties

- (const git_diff_delta *)git_diff_delta {
	return git_patch_get_delta(self.git_patch);
}

- (BOOL)isBinary {
	return (self.git_diff_delta->flags & GIT_DIFF_FLAG_BINARY) != 0;
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
	return git_patch_num_hunks(self.git_patch);
}

- (NSUInteger)sizeWithContext:(BOOL)includeContext hunkHeaders:(BOOL)includeHunkHeaders fileHeaders:(BOOL)includeFileHeaders {
	return git_patch_size(self.git_patch,
						  (includeContext == YES ? 1 : 0),
						  (includeHunkHeaders == YES ? 1 : 0),
						  (includeFileHeaders == YES ? 1 : 0));
}


- (void)enumerateHunksUsingBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block {
	NSParameterAssert(block != nil);

	for (NSUInteger idx = 0; idx < self.hunkCount; idx ++) {
		const git_diff_hunk *gitHunk;
		git_patch_get_hunk(&gitHunk, NULL, self.git_patch, idx);
		GTDiffHunk *hunk = [[GTDiffHunk alloc] initWithGitHunk:gitHunk hunkIndex:idx delta:self];
		// FIXME: Report error ?
		if (hunk == nil) return;

		BOOL shouldStop = NO;
		block(hunk, &shouldStop);
		if (shouldStop) return;
	}
}

@end
