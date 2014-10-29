//
//  GTFilterSource.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 2/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFilterSource.h"
#import "GTRepository.h"
#import "GTOID.h"

@implementation GTFilterSource

#pragma mark Lifecycle

- (id)initWithGitFilterSource:(const git_filter_source *)source {
	NSParameterAssert(source != NULL);

	self = [super init];
	if (self == nil) return nil;

	const char *path = git_repository_workdir(git_filter_source_repo(source));
	_repositoryURL = [NSURL fileURLWithPath:@(path)];
	
	_path = @(git_filter_source_path(source));

	const git_oid *gitOid = git_filter_source_id(source);
	if (gitOid != NULL) _OID = [[GTOID alloc] initWithGitOid:gitOid];

	git_filter_mode_t mode = git_filter_source_mode(source);
	if (mode == GIT_FILTER_TO_WORKTREE) {
		_mode = GTFilterSourceModeSmudge;
	} else {
		_mode = GTFilterSourceModeClean;
	}

	return self;
}

@end
