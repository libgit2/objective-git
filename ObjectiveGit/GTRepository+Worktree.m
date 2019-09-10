//
//  GTRepository+Worktree.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 25/07/2017.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Worktree.h"

@implementation GTRepository (Worktree)

+ (instancetype)repositoryWithWorktree:(GTWorktree *)worktree error:(NSError **)error {
	return [[self alloc] initWithWorktree:worktree error:error];
}

- (instancetype)initWithWorktree:(GTWorktree *)worktree error:(NSError **)error {
	NSParameterAssert(worktree != nil);

	git_repository *repo;
	int gitError = git_repository_open_from_worktree(&repo, worktree.git_worktree);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to open worktree"];
		return nil;
	}
	return [self initWithGitRepository:repo];
}

- (BOOL)isWorktree {
	return (BOOL)git_repository_is_worktree(self.git_repository);
}

- (NSURL *)commonGitDirectoryURL {
	const char *cPath = git_repository_commondir(self.git_repository);
	NSAssert(cPath, @"commondir is nil");

	NSString *path = @(cPath);
	NSAssert(path, @"commondir is nil");
	return [NSURL fileURLWithPath:path isDirectory:YES];
}

- (GTReference *)HEADReferenceInWorktreeWithName:(NSString *)name error:(NSError **)error {
	NSParameterAssert(name != nil);

	git_reference *ref;
	int gitError = git_repository_head_for_worktree(&ref, self.git_repository, name.UTF8String);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to resolve HEAD in worktree"];
		return nil;
	}

	return [[GTReference alloc] initWithGitReference:ref repository:self];
}

- (BOOL)isHEADDetached:(BOOL *)detached inWorktreeWithName:(NSString *)name error:(NSError **)error {
	NSParameterAssert(detached != nil);
	NSParameterAssert(name != nil);

	int gitError = git_repository_head_detached_for_worktree(self.git_repository, name.UTF8String);
	if (gitError < 0) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to resolve HEAD in worktree"];
		return NO;
	}

	*detached = (gitError == 1);

	return YES;
}

- (BOOL)setWorkingDirectoryURL:(NSURL *)URL updateGitLink:(BOOL)update error:(NSError **)error {
	NSParameterAssert(URL != nil);

	int gitError = git_repository_set_workdir(self.git_repository, URL.fileSystemRepresentation, update);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to set workdir"];
		return NO;
	}

	return YES;
}

- (NSArray<NSString *> *)worktreeNamesWithError:(NSError **)error {
	git_strarray names;
	int gitError = git_worktree_list(&names, self.git_repository);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to load worktree names"];
		return nil;
	}

	return [NSArray git_arrayWithStrarray:names];
}

- (GTWorktree *)lookupWorktreeWithName:(NSString *)name error:(NSError **)error {
	NSParameterAssert(name != nil);

	git_worktree *worktree;
	int gitError = git_worktree_lookup(&worktree, self.git_repository, name.UTF8String);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to lookup worktree"];
		return nil;
	}

	return [[GTWorktree alloc] initWithGitWorktree:worktree];
}

- (GTWorktree *)openWorktree:(NSError **)error {
	git_worktree *worktree;
	int gitError = git_worktree_open_from_repository(&worktree, self.git_repository);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to open worktree"];
		return nil;
	}

	return [[GTWorktree alloc] initWithGitWorktree:worktree];
}

@end
