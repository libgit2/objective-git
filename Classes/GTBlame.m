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
#import "GTOID+Private.h"

NSString *const GTBlameOptionsFlags = @"GTBlameOptionsFlags";
NSString *const GTBlameOptionsMinimumMatchCharacters = @"GTBlameOptionsMinimumMatchCharacters";
NSString *const GTBlameOptionsNewestCommitOID = @"GTBlameOptionsNewestCommitOID";
NSString *const GTBlameOptionsOldestCommitOID = @"GTBlameOptionsOldestCommitOID";
NSString *const GTBlameOptionsFirstLine = @"GTBlameOptionsFirstLine";
NSString *const GTBlameOptionsLastLine = @"GTBlameOptionsLastLine";

@interface GTBlame ()

@property (nonatomic, assign, readonly) git_blame *git_blame;

@end

@implementation GTBlame

+ (GTBlame *)blameWithFile:(NSString *)path inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	git_blame *blame = NULL;
	git_blame_options blame_options = GIT_BLAME_OPTIONS_INIT;

	blame_options.flags = (uint32_t)[options[GTBlameOptionsFlags] unsignedIntegerValue];
	blame_options.min_match_characters = (uint16_t)[options[GTBlameOptionsMinimumMatchCharacters] unsignedIntegerValue];
	blame_options.newest_commit = ((GTOID *)options[GTBlameOptionsNewestCommitOID]).git_oid_struct;
	blame_options.oldest_commit = ((GTOID *)options[GTBlameOptionsOldestCommitOID]).git_oid_struct;
	blame_options.min_line = (uint32_t)[options[GTBlameOptionsFirstLine] unsignedIntegerValue];
	blame_options.max_line = (uint32_t)[options[GTBlameOptionsLastLine] unsignedIntegerValue];
	
	int returnValue = git_blame_file(&blame, repository.git_repository, path.fileSystemRepresentation, &blame_options);
	
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create blame for file %@", path];
		return nil;
	}

	return [[self alloc] initWithGitBlame:blame];
}

+ (GTBlame *)blameWithFile:(NSString *)path inRepository:(GTRepository *)repository error:(NSError **)error {
	return [self blameWithFile:path inRepository:repository options:@{ GTBlameOptionsFlags: @(GTBlameOptionsNormal) } error:error];
}

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

- (void)enumerateHunksUsingBlock:(void (^)(GTBlameHunk *hunk, BOOL *stop))block {
	NSParameterAssert(block != nil);
	
	for (NSUInteger idx = 0; idx < self.hunkCount; idx++) {
		GTBlameHunk *hunk = [self hunkAtIndex:idx];
		
		BOOL shouldStop = NO;
		block(hunk, &shouldStop);
		if (shouldStop) return;
	}
}

- (NSArray *)hunks {
	__block NSMutableArray *hunks = [NSMutableArray arrayWithCapacity:self.hunkCount];
	[self enumerateHunksUsingBlock:^(GTBlameHunk *hunk, BOOL *stop) {
		[hunks addObject:hunk];
	}];
	
	return hunks;
}

- (GTBlameHunk *)hunkAtLineNumber:(NSUInteger)lineNumber {
	const git_blame_hunk *hunk = git_blame_get_hunk_byline(self.git_blame, (uint32)lineNumber);

	if (hunk == NULL) return nil;
	return [[GTBlameHunk alloc] initWithGitBlameHunk:*hunk];
}

@end
