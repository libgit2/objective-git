//
//  GTDiffDelta.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffDelta.h"

#import "GTDiff.h"
#import "GTDiffFile.h"
#import "GTDiffPatch.h"
#import "NSError+Git.h"

@interface GTDiffDelta ()

// The index of this delta within its parent `diff`.
@property (nonatomic, assign, readonly) NSUInteger deltaIndex;

@end

@implementation GTDiffDelta

#pragma mark Properties

- (BOOL)isBinary {
	return (self.git_diff_delta.flags & GIT_DIFF_FLAG_BINARY) != 0;
}

- (GTDiffFile *)oldFile {
	return [[GTDiffFile alloc] initWithGitDiffFile:self.git_diff_delta.old_file];
}

- (GTDiffFile *)newFile {
	return [[GTDiffFile alloc] initWithGitDiffFile:self.git_diff_delta.new_file];
}

- (GTDiffDeltaType)type {
	return (GTDiffDeltaType)self.git_diff_delta.status;
}

#pragma mark Lifecycle

- (instancetype)initWithDiff:(GTDiff *)diff deltaIndex:(NSUInteger)deltaIndex {
	self = [super init];
	if (self == nil) return nil;

	_diff = diff;
	_deltaIndex = deltaIndex;
	_git_diff_delta = *(git_diff_get_delta(self.diff.git_diff, self.deltaIndex));

	return self;
}

#pragma mark Patch Generation

- (GTDiffPatch *)generatePatch:(NSError **)error {
	git_patch *patch = NULL;
	int gitError = git_patch_from_diff(&patch, self.diff.git_diff, self.deltaIndex);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Patch generation failed for delta %@", self];
		return nil;
	}

	return [[GTDiffPatch alloc] initWithGitPatch:patch];
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ flags: %u, oldFile: %@, newFile: %@ }", self.class, self, (unsigned)self.git_diff_delta.flags, self.oldFile, self.newFile];
}

@end
