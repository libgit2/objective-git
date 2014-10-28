//
//  GTRemote.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTRemote.h"
#import "GTRepository.h"
#import "GTOID.h"
#import "GTCredential+Private.h"
#import "GTBranch.h"

#import "NSError+Git.h"
#import "NSArray+StringArray.h"
#import "EXTScope.h"

NSString * const GTRemoteRenameProblematicRefSpecs = @"GTRemoteRenameProblematicRefSpecs";

@interface GTRemote ()

@property (nonatomic, readonly, assign) git_remote *git_remote;
@end

@implementation GTRemote

#pragma mark Lifecycle

+ (instancetype)createRemoteWithName:(NSString *)name URLString:(NSString *)URLString inRepository:(GTRepository *)repo error:(NSError **)error {
	NSParameterAssert(name != nil);
	NSParameterAssert(URLString != nil);
	NSParameterAssert(repo != nil);

	git_remote *remote;
	int gitError = git_remote_create(&remote, repo.git_repository, name.UTF8String, URLString.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Remote creation failed" failureReason:@"Failed to create a remote named \"%@\" for \"%@\"", name, URLString];

		return nil;
	}

	return [[self alloc] initWithGitRemote:remote inRepository:repo];
}

+ (instancetype)remoteWithName:(NSString *)name inRepository:(GTRepository *)repo error:(NSError **)error {
	NSParameterAssert(name != nil);
	NSParameterAssert(repo != nil);

	git_remote *remote;
	int gitError = git_remote_load(&remote, repo.git_repository, name.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Remote loading failed" failureReason:nil];

		return nil;
	}

	return [[self alloc] initWithGitRemote:remote inRepository:repo];
}

- (instancetype)initWithGitRemote:(git_remote *)remote inRepository:(GTRepository *)repo {
	NSParameterAssert(remote != NULL);
	NSParameterAssert(repo != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;
	_repository = repo;

	return self;
}

- (void)dealloc {
	if (_git_remote != NULL) git_remote_free(_git_remote);
}

#pragma mark NSObject

- (BOOL)isEqual:(GTRemote *)object {
	if (object == self) return YES;
	if (![object isKindOfClass:[self class]]) return NO;

	return [object.name isEqual:self.name] && [object.URLString isEqual:self.URLString];
}

- (NSUInteger)hash {
	return self.name.hash ^ self.URLString.hash;
}

#pragma mark API

+ (BOOL)isSupportedURLString:(NSString *)URLString {
	NSParameterAssert(URLString != nil);

	return git_remote_supported_url(URLString.UTF8String) == GIT_OK;
}

+ (BOOL)isValidRemoteName:(NSString *)name {
	NSParameterAssert(name != nil);

	return git_remote_is_valid_name(name.UTF8String) == GIT_OK;
}

#pragma mark Properties

- (NSString *)name {
	const char *name = git_remote_name(self.git_remote);
	if (name == NULL) return nil;

	return @(name);
}

- (NSString *)URLString {
	const char *URLString = git_remote_url(self.git_remote);
	if (URLString == NULL) return nil;

	return @(URLString);
}

- (void)setURLString:(NSString *)URLString {
	git_remote_set_url(self.git_remote, URLString.UTF8String);
}

- (NSString *)pushURLString {
	const char *pushURLString = git_remote_pushurl(self.git_remote);
	if (pushURLString == NULL) return nil;

	return @(pushURLString);
}

- (void)setPushURLString:(NSString *)pushURLString {
	git_remote_set_pushurl(self.git_remote, pushURLString.UTF8String);
}

- (BOOL)updatesFetchHead {
	return git_remote_update_fetchhead(self.git_remote) != 0;
}

- (void)setUpdatesFetchHead:(BOOL)updatesFetchHead {
	git_remote_set_update_fetchhead(self.git_remote, updatesFetchHead);
}

- (GTRemoteAutoTagOption)autoTag {
	return (GTRemoteAutoTagOption)git_remote_autotag(self.git_remote);
}

- (void)setAutoTag:(GTRemoteAutoTagOption)autoTag {
	git_remote_set_autotag(self.git_remote, (git_remote_autotag_option_t)autoTag);
}

- (BOOL)isConnected {
	return git_remote_connected(self.git_remote) != 0;
}

#pragma mark Renaming

- (BOOL)rename:(NSString *)name error:(NSError **)error {
	NSParameterAssert(name != nil);
	
	git_strarray problematic_refspecs;
	
	int gitError = git_remote_rename(&problematic_refspecs, self.git_remote, name.UTF8String);
	if (gitError != GIT_OK) {
		NSArray *problematicRefspecs = [NSArray git_arrayWithStrarray:problematic_refspecs];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:problematicRefspecs forKey:GTRemoteRenameProblematicRefSpecs];

		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to rename remote" userInfo:userInfo failureReason:@"Couldn't rename remote %@ to %@", self.name, name];
	}

	git_strarray_free(&problematic_refspecs);

	return gitError == GIT_OK;
}

- (NSArray *)fetchRefspecs {
	__block git_strarray refspecs;
	int gitError = git_remote_get_fetch_refspecs(&refspecs, self.git_remote);
	if (gitError != GIT_OK) return nil;

	@onExit {
		git_strarray_free(&refspecs);
	};

	return [NSArray git_arrayWithStrarray:refspecs];

}

- (NSArray *)pushRefspecs {
	__block git_strarray refspecs;
	int gitError = git_remote_get_push_refspecs(&refspecs, self.git_remote);
	if (gitError != GIT_OK) return nil;

	@onExit {
		git_strarray_free(&refspecs);
	};
	
	return [NSArray git_arrayWithStrarray:refspecs];
}

#pragma mark Update the remote

- (BOOL)saveRemote:(NSError **)error {
	int gitError = git_remote_save(self.git_remote);
	if (gitError != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to save remote configuration."];
		}
		return NO;
	}
	return YES;
}

- (BOOL)updateURLString:(NSString *)URLString error:(NSError **)error {
	NSParameterAssert(URLString != nil);

	if ([self.URLString isEqualToString:URLString]) return YES;

	int gitError = git_remote_set_url(self.git_remote, URLString.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to update remote URL string."];
		}
		return NO;
	}
	return [self saveRemote:error];
}

- (BOOL)addFetchRefspec:(NSString *)fetchRefspec error:(NSError **)error {
	NSParameterAssert(fetchRefspec != nil);

	if ([self.fetchRefspecs containsObject:fetchRefspec]) return YES;

	int gitError = git_remote_add_fetch(self.git_remote, fetchRefspec.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to add fetch refspec."];
		}
		return NO;
	}
	return [self saveRemote:error];
}

@end
