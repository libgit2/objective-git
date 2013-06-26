//
//  GTSubmodule.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-05-29.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTSubmodule.h"
#import "GTOID.h"
#import "GTRepository.h"
#import "NSError+Git.h"

@implementation GTSubmodule

#pragma mark Properties

- (GTSubmoduleIgnoreRule)ignoreRule {
	return (GTSubmoduleIgnoreRule)git_submodule_ignore(self.git_submodule);
}

- (void)setIgnoreRule:(GTSubmoduleIgnoreRule)ignoreRule {
	git_submodule_set_ignore(self.git_submodule, (git_submodule_ignore_t)ignoreRule);
}

- (GTOID *)indexOID {
	const git_oid *oid = git_submodule_index_id(self.git_submodule);
	if (oid == NULL) return nil;

	return [[GTOID alloc] initWithGitOid:oid];
}

- (GTOID *)HEADOID {
	const git_oid *oid = git_submodule_head_id(self.git_submodule);
	if (oid == NULL) return nil;

	return [[GTOID alloc] initWithGitOid:oid];
}

- (GTOID *)workingDirectoryOID {
	const git_oid *oid = git_submodule_wd_id(self.git_submodule);
	if (oid == NULL) return nil;

	return [[GTOID alloc] initWithGitOid:oid];
}

- (NSString *)name {
	const char *cName = git_submodule_name(self.git_submodule);
	if (cName == NULL) return nil;

	return @(cName);
}

#pragma mark Lifecycle

- (id)initWithGitSubmodule:(git_submodule *)submodule parentRepository:(GTRepository *)repository {
	NSParameterAssert(submodule != NULL);
	NSParameterAssert(repository != nil);

	self = [super init];
	if (self == nil) return nil;
	
	_parentRepository = repository;
	_git_submodule = submodule;

	return self;
}

#pragma mark Inspection

- (GTSubmoduleStatus)status:(NSError **)error {
	unsigned status;
	int gitError = git_submodule_status(&status, self.git_submodule);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to get submodule status."];
		return GTSubmoduleStatusUnknown;
	}

	return status;
}

#pragma mark Manipulation

- (BOOL)reload:(NSError **)error {
	int gitError = git_submodule_reload(self.git_submodule);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to reload submodule."];
		return NO;
	}

	return YES;
}

- (BOOL)sync:(NSError **)error {
	int gitError = git_submodule_sync(self.git_submodule);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to synchronize submodule."];
		return NO;
	}

	return YES;
}

- (GTRepository *)submoduleRepository:(NSError **)error {
	git_repository *repo;
	int gitError = git_submodule_open(&repo, self.git_submodule);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to open submodule repository."];
		return nil;
	}

	return [[GTRepository alloc] initWithGitRepository:repo];
}

- (BOOL)writeToParentConfigurationDestructively:(BOOL)overwrite error:(NSError **)error {
	int gitError = git_submodule_init(self.git_submodule, (overwrite ? 1 : 0));
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to initialize submodule."];
		return NO;
	}

	return YES;
}

@end
