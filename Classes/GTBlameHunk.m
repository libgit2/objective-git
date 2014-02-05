//
//  GTBlameHunk.m
//  ObjectiveGitFramework
//
//  Created by David Catmull on 11/6/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTBlameHunk.h"
#import "GTOID.h"
#import "GTSignature.h"

@implementation GTBlameHunk

- (instancetype)initWithGitBlameHunk:(git_blame_hunk)hunk {
	self = [super init];
	if (self == nil)
		return nil;

	_git_blame_hunk = hunk;
	return self;
}

- (NSUInteger)lineCount {
	return _git_blame_hunk.lines_in_hunk;
}

- (NSUInteger)finalStartLineNumber {
	return _git_blame_hunk.final_start_line_number;
}

- (GTOID *)finalCommitID {
	return [[GTOID alloc] initWithGitOid:&_git_blame_hunk.final_commit_id];
}

- (GTSignature *)finalSignature {
	return [[GTSignature alloc] initWithGitSignature:_git_blame_hunk.final_signature];
}

- (GTOID *)originalCommitID {
	return [[GTOID alloc] initWithGitOid:&_git_blame_hunk.orig_commit_id];
}

- (NSUInteger)originalStartLineNumber {
	return _git_blame_hunk.orig_start_line_number;
}

- (GTSignature *)originalSignature {
	return [[GTSignature alloc] initWithGitSignature:_git_blame_hunk.orig_signature];
}

- (NSString *)originalPath {
	return [[NSString alloc] initWithUTF8String:_git_blame_hunk.orig_path];
}

- (BOOL)isBoundary {
	return _git_blame_hunk.boundary;
}

@end
