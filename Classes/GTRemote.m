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

@interface GTRemote () {
	GTRepository *repository;
}
@property (nonatomic, readonly, assign) git_remote *git_remote;
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

+ (instancetype)remoteWithName:(NSString *)name inRepository:(GTRepository *)repo {
	return [[self alloc] initWithName:name inRepository:repo];
}

- (instancetype)initWithName:(NSString *)name inRepository:(GTRepository *)repo {
	self = [super init];
	if (self == nil) return nil;

	int gitError = git_remote_load(&_git_remote, repo.git_repository, name.UTF8String);
	if (gitError != GIT_OK) return nil;

	repository = repo;

	return self;
}

- (id)initWithGitRemote:(git_remote *)remote {
	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;

	return self;
}

- (GTRepository *)repository {
	if (repository == nil) {
		repository = [[GTRepository alloc] initWithGitRepository:git_remote_owner(self.git_remote)];
	}
	return repository;
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

#pragma mark Fetch

typedef int  (^GTCredentialAcquireBlock)(git_cred **cred, GTCredentialType allowedTypes, NSURL *url);

typedef void (^GTRemoteFetchProgressBlock)(NSString *message, int length);

typedef int  (^GTRemoteFetchCompletionBlock)(GTRemoteCompletionType type);

typedef int  (^GTRemoteFetchUpdateTipsBlock)(GTReference *ref, GTOID *a, GTOID *b);

typedef struct {
	__unsafe_unretained GTRemote *myself;
	__unsafe_unretained GTCredentialAcquireBlock credBlock;
	__unsafe_unretained GTRemoteFetchProgressBlock progressBlock;
	__unsafe_unretained GTRemoteFetchCompletionBlock completionBlock;
	__unsafe_unretained GTRemoteFetchUpdateTipsBlock updateTipsBlock;
} GTRemoteFetchInfo;

static int fetch_cred_acquire_cb(git_cred **cred, const char *urlStr, const char *username_from_url, unsigned int allowed_types, void *payload) {
	GTRemoteFetchInfo *info = (GTRemoteFetchInfo *)payload;

	if (info->credBlock == nil) {
		NSString *errorMsg = [NSString stringWithFormat:@"No credential block passed, but authentication was requested for remote %@", info->myself.name];
		giterr_set_str(GIT_EUSER, errorMsg.UTF8String);
		return GIT_ERROR;
	}

	NSURL *url = [NSURL URLWithString:@(urlStr)];
	NSCAssert(url != nil, @"Failed to convert %s to an URL", urlStr);

	return info->credBlock(cred, (GTCredentialType)allowed_types, url);
}

static void fetch_progress(const char *str, int len, void *payload) {
	GTRemoteFetchInfo *info = (GTRemoteFetchInfo *)payload;

	if (info->progressBlock == nil) return;

	info->progressBlock(@(str), len);
}

static int fetch_completion(git_remote_completion_type type, void *payload) {
	GTRemoteFetchInfo *info = (GTRemoteFetchInfo *)payload;

	if (info->completionBlock == nil) return GIT_OK;

	return info->completionBlock((GTRemoteCompletionType)type);
}

static int fetch_update_tips(const char *refname, const git_oid *a, const git_oid *b, void *payload) {
	GTRemoteFetchInfo *info = (GTRemoteFetchInfo *)payload;
	if (info->updateTipsBlock == nil) return GIT_OK;

	NSError *error = nil;
	GTReference *ref = [GTReference referenceByLookingUpReferencedNamed:@(refname) inRepository:info->myself.repository error:&error];
	if (ref == nil) {
		NSLog(@"Error resolving reference %s: %@", refname, error);
	}

	GTOID *oid_a = [[GTOID alloc] initWithGitOid:a];
	GTOID *oid_b = [[GTOID alloc] initWithGitOid:b];
	return info->updateTipsBlock(ref, oid_a, oid_b);
}

- (BOOL)fetchWithError:(NSError **)error credentials:(GTCredentialAcquireBlock)credBlock progress:(GTRemoteFetchProgressBlock)progressBlock completion:(GTRemoteFetchCompletionBlock)completionBlock updateTips:(GTRemoteFetchUpdateTipsBlock)updateTipsBlock {
	GTRemoteFetchInfo payload = {
		.myself = self,
		.credBlock = credBlock,
		.progressBlock = progressBlock,
		.completionBlock = completionBlock,
		.updateTipsBlock = updateTipsBlock,
	};

	git_remote_callbacks remote_callbacks = GIT_REMOTE_CALLBACKS_INIT;
	remote_callbacks.progress = fetch_progress;
	remote_callbacks.completion = fetch_completion;
	remote_callbacks.update_tips = fetch_update_tips;
	remote_callbacks.payload = &payload;

	int gitError = git_remote_set_callbacks(self.git_remote, &remote_callbacks);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to set remote callbacks for fetch"];
		return NO;
	}

	git_remote_set_cred_acquire_cb(self.git_remote, fetch_cred_acquire_cb, (__bridge void *)(self));

	gitError = git_remote_connect(self.git_remote, GIT_DIRECTION_FETCH);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to connect remote"];
		return NO;
	}

	gitError = git_remote_download(self.git_remote, NULL, NULL);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to fetch"];
		return NO;
	}

	gitError = git_remote_update_tips(self.git_remote);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to update remote tips"];
		return NO;
	}

	return YES;
}

- (void)stop {
	git_remote_stop(self.git_remote);
}

- (BOOL)isConnected {
	return (BOOL)git_remote_connected(self.git_remote) == 0;
}

@end
