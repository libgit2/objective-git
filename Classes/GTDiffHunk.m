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

@property (nonatomic, strong, readonly) GTDiffDelta *delta;
@property (nonatomic, readonly) NSUInteger hunkIndex;

@end

@implementation GTDiffHunk

- (instancetype)initWithDelta:(GTDiffDelta *)delta hunkIndex:(NSUInteger)hunkIndex {
	self = [super init];
	if (self == nil) return nil;
	
	_delta = delta;
	_hunkIndex = hunkIndex;
	
	const char *headerCString;
	size_t headerLength;
	size_t lineCount;
	int result = git_diff_patch_get_hunk(NULL, &headerCString, &headerLength, &lineCount, delta.git_diff_patch, hunkIndex);
	if (result != GIT_OK) return nil;
	
	_header = [[[NSString alloc] initWithBytes:headerCString length:headerLength encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
	_lineCount = lineCount;

	return self;
}

- (void)enumerateLinesInHunkUsingBlock:(void (^)(GTDiffLine *line, BOOL *stop))block {
	NSParameterAssert(block != nil);
	
	for (NSUInteger idx = 0; idx < self.lineCount; idx ++) {
		char lineOrigin;
		const char *content;
		size_t contentLength;
		int oldLineNumber;
		int newLineNumber;
		int result = git_diff_patch_get_line_in_hunk(&lineOrigin, &content, &contentLength, &oldLineNumber, &newLineNumber, self.delta.git_diff_patch, self.hunkIndex, idx);
		if (result != GIT_OK) continue;
		
		NSString *lineString = [[[NSString alloc] initWithBytes:content length:contentLength encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
		GTDiffLine *line = [[GTDiffLine alloc] initWithContent:lineString oldLineNumber:oldLineNumber newLineNumber:newLineNumber origin:lineOrigin];
		BOOL stop = NO;
		block(line, &stop);
		if (stop) return;
	}
}

@end
