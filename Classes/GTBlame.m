//
//  GTBlame.m
//  ObjectiveGitFramework
//
//  Created by David Catmull on 11/6/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTBlame.h"
#import "GTBlameHunk.h"
#import "GTOID.h"
#import "GTRepository.h"
#import "GTSignature.h"
#import "NSError+Git.h"

@interface GTBlame ()

@property (nonatomic, assign, readonly) git_blame *git_blame;

@end

@implementation GTBlame

- (instancetype)initWithGitBlame:(git_blame *)blame {
	NSParameterAssert(blame != NULL);
	
	self = [super init];
	if (self == nil) return nil;
	
	_git_blame = blame;
	
	return self;
}

- (void)dealloc {
	if (_git_blame != NULL) {
		git_blame_free(_git_blame);
		_git_blame = NULL;
	}
}

- (NSUInteger)hunkCount {
	return git_blame_get_hunk_count(self.git_blame);
}

- (GTBlameHunk *)hunkAtIndex:(NSUInteger)index {
	const git_blame_hunk *hunk = git_blame_get_hunk_byindex(self.git_blame, (uint32_t)index);

	if (hunk == NULL) return nil;
	return [[GTBlameHunk alloc] initWithGitBlameHunk:*hunk];
}

- (void)enumerateHunksUsingBlock:(void (^)(GTBlameHunk *hunk, NSUInteger index, BOOL *stop))block {
	NSParameterAssert(block != nil);
	
	for (NSUInteger index = 0; index < self.hunkCount; index++) {
		GTBlameHunk *hunk = [self hunkAtIndex:index];
		
		BOOL shouldStop = NO;
		block(hunk, index, &shouldStop);
		if (shouldStop) return;
	}
}

- (NSArray *)hunks {
	__block NSMutableArray *hunks = [NSMutableArray arrayWithCapacity:self.hunkCount];
	[self enumerateHunksUsingBlock:^(GTBlameHunk *hunk, NSUInteger index, BOOL *stop) {
		[hunks addObject:hunk];
	}];
	
	return hunks;
}

- (GTBlameHunk *)hunkAtLineNumber:(NSUInteger)lineNumber {
	const git_blame_hunk *hunk = git_blame_get_hunk_byline(self.git_blame, (uint32_t)lineNumber);

	if (hunk == NULL) return nil;
	return [[GTBlameHunk alloc] initWithGitBlameHunk:*hunk];
}

- (BOOL)isEqual:(GTBlame *)otherBlame {
	if (self == otherBlame) return YES;
	if (![otherBlame.class isKindOfClass:GTBlame.class]) return NO;
	
	if (![self.hunks isEqual:otherBlame.hunks]) return NO;

	return YES;
}

- (NSUInteger)hash {
	return self.hunks.hash ^ self.hunkCount;
}

@end
