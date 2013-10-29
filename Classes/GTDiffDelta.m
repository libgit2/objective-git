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

@interface GTDiffDelta () {
	GTDiffFile *_oldFile, *_newFile;
}
@property (nonatomic, assign, readonly) const git_diff_delta *git_diff_delta;
@property (nonatomic, strong, readonly) GTDiff *diff;
@property (nonatomic, assign, readonly) NSInteger deltaIndex;
@property (strong) NSArray *patchHunks;
@end

@implementation GTDiffDelta

- (instancetype)initWithGitDelta:(const git_diff_delta *)delta deltaIndex:(NSInteger)idx inDiff:(GTDiff *)diff {
	NSParameterAssert(delta != NULL);
	
	self = [super init];
	if (self == nil) return nil;
	
	_git_diff_delta = delta;
	_diff = diff;
	_deltaIndex = idx;

	// Build the patch
	git_patch *gitPatch;
	git_patch_from_diff(&gitPatch, self.diff.git_diff, self.deltaIndex);
	_git_patch = gitPatch;

	size_t adds = 0;
	size_t deletes = 0;
	size_t contexts = 0;
	git_patch_line_stats(&contexts, &adds, &deletes, gitPatch);

	_addedLinesCount = adds;
	_deletedLinesCount = deletes;
	_contextLinesCount = contexts;

	return self;
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ flags: %u, oldFile: %@, newFile: %@", super.debugDescription, self.git_diff_delta->flags, self.oldFile, self.newFile];
}

#pragma mark - Properties

- (BOOL)isBinary {
	// We have to generate the patch to know if the file is binary or not
	git_patch_from_diff(NULL, self.diff.git_diff, self.deltaIndex);
	return (self.git_diff_delta->flags & GIT_DIFF_FLAG_BINARY) != 0;
}

- (GTDiffFile *)oldFile {
	if (_oldFile == nil)
		_oldFile = [[GTDiffFile alloc] initWithGitDiffFile:self.git_diff_delta->old_file];
	return _oldFile;
}

- (GTDiffFile *)newFile {
	if (_newFile == nil) {
		_newFile = [[GTDiffFile alloc] initWithGitDiffFile:self.git_diff_delta->new_file];
	}
	return _newFile;
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

- (void)buildPatchHunksWithBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block {
	NSMutableArray *patchHunks = [NSMutableArray arrayWithCapacity:self.hunkCount];

	for (NSUInteger idx = 0; idx < self.hunkCount; idx ++) {
		const git_diff_hunk *gitHunk;
		git_patch_get_hunk(&gitHunk, NULL, self.git_patch, idx);
		GTDiffHunk *hunk = [[GTDiffHunk alloc] initWithGitHunk:gitHunk hunkIndex:idx delta:self];
		// FIXME: Report error ?
		if (hunk == nil) return;

		[patchHunks addObject:hunk];

		if (block == nil) continue;

		BOOL shouldStop = NO;
		block(hunk, &shouldStop);
		if (shouldStop) return;
	}

	self.patchHunks = patchHunks;
}

- (void)enumerateHunksUsingBlock:(void (^)(GTDiffHunk *hunk, BOOL *stop))block {
	NSParameterAssert(block != nil);

	if (self.patchHunks == nil) {
		[self buildPatchHunksWithBlock:block];
		return;
	}
	[self.patchHunks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		block(obj, stop);
	}];
}

@end
