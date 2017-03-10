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

#import "git2/errors.h"

@interface GTSubmodule ()
@property (nonatomic, assign, readonly) git_submodule *git_submodule;
@end

@implementation GTSubmodule

#pragma mark Properties

- (GTSubmoduleIgnoreRule)ignoreRule {
	return (GTSubmoduleIgnoreRule)git_submodule_ignore(self.git_submodule);
}

- (GTSubmodule *)submoduleByUpdatingIgnoreRule:(GTSubmoduleIgnoreRule)ignoreRule error:(NSError **)error {
	int result = git_submodule_set_ignore(self.parentRepository.git_repository, git_submodule_name(self.git_submodule), (git_submodule_ignore_t)ignoreRule);
	if (result != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:result description:@"Couldn't set submodule ignore rule."];
		}
		return nil;
	}

	return [self.parentRepository submoduleWithName:self.name error:error];
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

- (NSString *)path {
	const char *cPath = git_submodule_path(self.git_submodule);
	if (cPath == NULL) return nil;

	return @(cPath);
}

- (NSString *)URLString {
	const char *cURL = git_submodule_url(self.git_submodule);
	if (cURL == NULL) return nil;

	return @(cURL);
}

#pragma mark Lifecycle

- (void)dealloc {
	if (_git_submodule != NULL) {
		git_submodule_free(_git_submodule);
	}
}

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

- (instancetype)initWithGitSubmodule:(git_submodule *)submodule parentRepository:(GTRepository *)repository {
	NSParameterAssert(submodule != NULL);
	NSParameterAssert(repository != nil);

	self = [super init];
	if (self == nil) return nil;
	
	_parentRepository = repository;
	_git_submodule = submodule;

	return self;
}

#pragma mark Inspection

- (GTSubmoduleStatus)statusWithIgnoreRule:(GTSubmoduleIgnoreRule)ignoreRule error:(NSError **)error {
	unsigned status;
	int gitError = git_submodule_status(&status, self.parentRepository.git_repository, git_submodule_name(self.git_submodule), (git_submodule_ignore_t)ignoreRule);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get submodule %@ status.", self.name];
		return GTSubmoduleStatusUnknown;
	}

	return status;
}

- (GTSubmoduleStatus)status:(NSError **)error {
	return [self statusWithIgnoreRule:self.ignoreRule error:error];
}

#pragma mark Manipulation

- (BOOL)reload:(NSError **)error {
	int gitError = git_submodule_reload(self.git_submodule, 0);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to reload submodule %@.", self.name];
		return NO;
	}

	return YES;
}

- (BOOL)sync:(NSError **)error {
	int gitError = git_submodule_sync(self.git_submodule);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to synchronize submodule %@.", self.name];
		return NO;
	}

	return YES;
}

- (GTRepository *)submoduleRepository:(NSError **)error {
	git_repository *repo;
	int gitError = git_submodule_open(&repo, self.git_submodule);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to open submodule %@ repository.", self.name];
		return nil;
	}

	return [[GTRepository alloc] initWithGitRepository:repo];
}

- (BOOL)writeToParentConfigurationDestructively:(BOOL)overwrite error:(NSError **)error {
	int gitError = git_submodule_init(self.git_submodule, (overwrite ? 1 : 0));
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to initialize submodule %@.", self.name];
		return NO;
	}

	return YES;
}

- (BOOL)addToIndex:(NSError **)error {
	int gitError = git_submodule_add_to_index(self.git_submodule, 0);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to add submodule %@ to its parent's index.", self.name];
		return NO;
	}

	return YES;
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ name: %@, indexOID: %@, HEADOID: %@, workingDirectoryOID: %@ }", self.class, self, self.name, self.indexOID, self.HEADOID, self.workingDirectoryOID];
}

- (NSUInteger)hash {
	return self.name.hash;
}

- (BOOL)isEqual:(GTSubmodule *)submodule {
	if (self == submodule) return YES;
	if (![submodule isKindOfClass:GTSubmodule.class]) return NO;

	return [self.parentRepository isEqual:submodule.parentRepository] && [self.name isEqual:submodule.name];
}

@end
