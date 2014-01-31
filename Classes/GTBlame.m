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

+ (GTBlame *)blameWithFile:(NSString *)path inRepository:(GTRepository *)repository options:(GTBlameOptionsFlags)options error:(NSError **)error {
	git_blame *blame = NULL;
	git_blame_options blame_options = GIT_BLAME_OPTIONS_INIT;
	blame_options.flags = (git_blame_flag_t)options;
	
	int returnValue = git_blame_file(&blame, repository.git_repository, path.fileSystemRepresentation, &blame_options);
	
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create blame for file %@", path];
		return nil;
	}

	return [[self alloc] initWithGitBlame:blame];
}

+ (GTBlame *)blameWithFile:(NSString *)path inRepository:(GTRepository *)repository error:(NSError **)error {
	return [self blameWithFile:path inRepository:repository options:GTBlameOptionsNormal error:error];
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

	if (hunk == NULL)
		return nil;
	return [[GTBlameHunk alloc] initWithGitBlameHunk:*hunk];
}

@end
