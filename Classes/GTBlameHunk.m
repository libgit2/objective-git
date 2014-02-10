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

- (NSRange)lines {
	return NSMakeRange(self.git_blame_hunk.final_start_line_number, self.git_blame_hunk.lines_in_hunk);
}

- (GTOID *)finalCommitOID {
	git_oid oid = self.git_blame_hunk.final_commit_id;
	return [GTOID oidWithGitOid:&oid];
}

- (GTSignature *)finalSignature {
	return [[GTSignature alloc] initWithGitSignature:self.git_blame_hunk.final_signature];
}

- (NSString *)originalPath {
	return @(self.git_blame_hunk.orig_path);
}

- (BOOL)isBoundary {
	return self.git_blame_hunk.boundary;
}

- (BOOL)isEqual:(GTBlameHunk *)otherHunk {
	if (self == otherHunk) return YES;
	if (![otherHunk isKindOfClass:GTBlameHunk.class]) return NO;
	
	if (!NSEqualRanges(self.lines, otherHunk.lines)) return NO;
	if (![self.finalCommitOID isEqual:otherHunk.finalCommitOID]) return NO;
	if (![self.finalSignature isEqual:otherHunk.finalSignature]) return NO;
	if (![self.originalPath isEqualToString:otherHunk.originalPath]) return NO;
	if (self.isBoundary != otherHunk.isBoundary) return NO;
	
	return YES;
}

- (NSUInteger)hash {
	return self.lines.location ^ self.lines.length;
}

@end
