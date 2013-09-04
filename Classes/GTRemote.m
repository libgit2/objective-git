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
#import "NSError+Git.h"

@interface GTRemote ()
@property (nonatomic, readonly, assign) git_remote *git_remote;
@property (nonatomic, strong) GTRepository *repository;
@end

@implementation GTRemote

- (void)dealloc {
	if (_git_remote != NULL) git_remote_free(_git_remote);
}

- (BOOL)isEqual:(GTRemote *)object {
	if (object == self) return YES;
	if (![object isKindOfClass:[self class]]) return NO;

	return [object.name isEqual:self.name] && [object.URLString isEqual:self.URLString];
}

- (NSUInteger)hash {
	return self.name.hash ^ self.URLString.hash;
}

#pragma mark API

+ (BOOL)isValidURL:(NSString *)URL {
	NSParameterAssert(URL != nil);

	return git_remote_valid_url(URL.UTF8String) == GIT_OK;
}

+ (BOOL)isSupportedURL:(NSString *)URL {
	NSParameterAssert(URL != nil);

	return git_remote_supported_url(URL.UTF8String) == GIT_OK;
}

+ (BOOL)isValidRemoteName:(NSString *)name {
	NSParameterAssert(name != nil);

	return git_remote_is_valid_name(name.UTF8String) == GIT_OK;
}

+ (instancetype)createRemoteWithName:(NSString *)name url:(NSString *)URL inRepository:(GTRepository *)repo {
	NSParameterAssert(URL != nil);

	return [[self alloc] initWithName:name url:URL inRepository:repo error:NULL];
}

+ (instancetype)remoteWithName:(NSString *)name inRepository:(GTRepository *)repo {
	return [[self alloc] initWithName:name url:nil inRepository:repo error:NULL];
}

- (instancetype)initWithName:(NSString *)name url:(NSString *)URL inRepository:(GTRepository *)repo error:(NSError **)error {
	NSParameterAssert(name != nil);
	NSParameterAssert(repo != nil);

	self = [super init];
	if (self == nil) return nil;
	int gitError = GIT_OK;

	if (URL) {
		// An URL was provided, try to create a new remote
		gitError = git_remote_create(&_git_remote, repo.git_repository, name.UTF8String, URL.UTF8String);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Remote creation failed" failureReason:nil];

			return nil;
		}
	} else {
		// No URL provided, we're loading an existing remote
		gitError = git_remote_load(&_git_remote, repo.git_repository, name.UTF8String);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Remote loading failed" failureReason:nil];

			return nil;
		}
	}

	_repository = repo;

	return self;
}

- (id)initWithGitRemote:(git_remote *)remote inRepository:(GTRepository *)repo {
	NSParameterAssert(remote != NULL);
	NSParameterAssert(repo != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;

	_repository = repo;

	return self;
}

- (GTRepository *)repository {
	return _repository;
}

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
	return git_remote_update_fetchhead(self.git_remote) == 0;
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

#pragma mark Renaming

typedef int (^GTRemoteRenameBlock)(NSString *refspec);

typedef struct {
	__unsafe_unretained GTRemote *myself;
	__unsafe_unretained GTRemoteRenameBlock renameBlock;
} GTRemoteRenameInfo;

static int remote_rename_problem_cb(const char *problematic_refspec, void *payload) {
	GTRemoteRenameInfo *info = payload;
	if (info->renameBlock == nil) return GIT_OK;

	return info->renameBlock(@(problematic_refspec));
}

- (BOOL)rename:(NSString *)name failureBlock:(GTRemoteRenameBlock)renameBlock error:(NSError **)error {
	NSParameterAssert(name != nil);

	GTRemoteRenameInfo info = {
		.myself = self,
		.renameBlock = renameBlock,
	};

	int gitError = git_remote_rename(self.git_remote, name.UTF8String, remote_rename_problem_cb, &info);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to rename remote" failureReason:@"Couldn't rename remote %@ to %@", self.name, name];
	}
	return gitError == GIT_OK;
}

- (BOOL)rename:(NSString *)name error:(NSError **)error {
	return [self rename:name failureBlock:nil error:error];
}

#pragma mark Fetch

typedef int  (^GTCredentialAcquireBlock)(git_cred **cred, GTCredentialType allowedTypes, NSString *URL, NSString *username);

typedef void (^GTRemoteTransferProgressBlock)(const git_transfer_progress *stats, BOOL *stop);

typedef struct {
	__unsafe_unretained GTRemote *myself;
	__unsafe_unretained GTCredentialAcquireBlock credBlock;
	__unsafe_unretained GTRemoteTransferProgressBlock progressBlock;
} GTRemoteFetchInfo;

static int fetch_cred_acquire_cb(git_cred **cred, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload) {
	GTRemoteFetchInfo *info = payload;

	if (info->credBlock == nil) {
		NSString *errorMsg = [NSString stringWithFormat:@"No credential block passed, but authentication was requested for remote %@", info->myself.name];
		giterr_set_str(GIT_EUSER, errorMsg.UTF8String);
		return GIT_ERROR;
	}

	NSString *URL = url ? @(url) : nil;
	NSString *userName = username_from_url ? @(username_from_url) : nil;

	return info->credBlock(cred, (GTCredentialType)allowed_types, URL, userName);
}

int transfer_progress_cb(const git_transfer_progress *stats, void *payload) {
	GTRemoteFetchInfo *info = payload;
	BOOL stop = NO;

	if (info->progressBlock != nil) info->progressBlock(stats, &stop);

	return stop ? -1 : 0;
}

- (BOOL)fetchWithError:(NSError **)error credentials:(GTCredentialAcquireBlock)credBlock progress:(GTRemoteTransferProgressBlock)progressBlock {
	@synchronized (self) {
		GTRemoteFetchInfo payload = {
			.myself = self,
			.credBlock = credBlock,
			.progressBlock = progressBlock,
		};

		git_remote_set_cred_acquire_cb(self.git_remote, fetch_cred_acquire_cb, &payload);

		int gitError = git_remote_connect(self.git_remote, GIT_DIRECTION_FETCH);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to connect remote"];
			goto error;
		}

		gitError = git_remote_download(self.git_remote, transfer_progress_cb, &payload);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to fetch remote"];
			goto error;
		}

		gitError = git_remote_update_tips(self.git_remote);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to update tips"];
			goto error;
		}

	error:
		// Cleanup
		git_remote_disconnect(self.git_remote);
		git_remote_set_cred_acquire_cb(self.git_remote, NULL, NULL);

		return gitError == GIT_OK;
	}
}

- (BOOL)isConnected {
	return (BOOL)git_remote_connected(self.git_remote) == 0;
}

@end
