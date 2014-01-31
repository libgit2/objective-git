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
	if (self == nil) return nil;

	_git_blame_hunk = hunk;
	return self;
}

- (NSUInteger)lineCount {
	return self.git_blame_hunk.lines_in_hunk;
}

- (NSUInteger)finalStartLineNumber {
	return self.git_blame_hunk.final_start_line_number;
}

- (GTOID *)finalCommitID {
	git_oid oid = self.git_blame_hunk.final_commit_id;
	return [GTOID oidWithGitOid:&oid];
}

- (GTSignature *)finalSignature {
	return [[GTSignature alloc] initWithGitSignature:self.git_blame_hunk.final_signature];
}

- (GTOID *)originalCommitID {
	git_oid oid = self.git_blame_hunk.orig_commit_id;
	return [GTOID oidWithGitOid:&oid];
}

- (NSUInteger)originalStartLineNumber {
	return self.git_blame_hunk.orig_start_line_number;
}

- (GTSignature *)originalSignature {
	return [[GTSignature alloc] initWithGitSignature:self.git_blame_hunk.orig_signature];
}

- (NSString *)originalPath {
	return @(self.git_blame_hunk.orig_path);
}

- (BOOL)isBoundary {
	return self.git_blame_hunk.boundary;
}

@end
