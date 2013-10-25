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
#import "GTPatch.h"
#import "GTDiff.h"

@interface GTDiffDelta () {
	// Some cache ivars
	GTPatch *_patch;
	GTDiffFile *_oldFile, *_newFile;
}
@property (nonatomic, assign, readonly) const git_diff_delta *git_diff_delta;
@property (nonatomic, strong, readonly) GTDiff *diff;
@property (nonatomic, assign, readonly) NSInteger deltaIndex;
@end

@implementation GTDiffDelta

- (instancetype)initWithGitDelta:(const git_diff_delta *)delta deltaIndex:(NSInteger)idx inDiff:(GTDiff *)diff {
	NSParameterAssert(delta != NULL);
	
	self = [super init];
	if (self == nil) return nil;
	
	_git_diff_delta = delta;
	_diff = diff;
	_deltaIndex = idx;

	return self;
}

#pragma mark - Properties

- (BOOL)isBinary {
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

- (GTPatch *)patch {
	if (_patch == nil) {
		git_patch *gitPatch;
		git_patch_from_diff(&gitPatch, self.diff.git_diff, self.deltaIndex);
		_patch = [[GTPatch alloc] initWithGitPatch:gitPatch inDelta:self];
	}
	return _patch;
}

@end
