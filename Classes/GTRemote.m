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
	GTRepository *_repository;
}
@property (nonatomic, readonly, assign) git_remote *git_remote;
@end

@implementation GTRemote
@synthesize repository;

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
	NSParameterAssert(name != nil);
	NSParameterAssert(repository != nil);

	self = [super init];
	if (self == nil) return nil;

	int gitError = git_remote_load(&_git_remote, repo.git_repository, name.UTF8String);
	if (gitError != GIT_OK) return nil;

	_repository = repo;

	return self;
}

- (id)initWithGitRemote:(git_remote *)remote {
	NSParameterAssert(remote != NULL);
	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;

	return self;
}

- (GTRepository *)repository {
	if (_repository == nil) {
		_repository = [[GTRepository alloc] initWithGitRepository:git_remote_owner(self.git_remote)];
	}
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

#pragma mark Fetch

typedef int  (^GTCredentialAcquireBlock)(git_cred **cred, GTCredentialType allowedTypes, NSString *url, NSString *username);

typedef void (^GTRemoteFetchProgressBlock)(NSString *message, int length, BOOL *stop);

typedef int  (^GTRemoteFetchCompletionBlock)(GTRemoteCompletionType type, BOOL *stop);

typedef int  (^GTRemoteFetchUpdateTipsBlock)(GTReference *ref, GTOID *a, GTOID *b, BOOL *stop);

typedef struct {
	__unsafe_unretained GTRemote *myself;
	__unsafe_unretained GTCredentialAcquireBlock credBlock;
	__unsafe_unretained GTRemoteFetchProgressBlock progressBlock;
	__unsafe_unretained GTRemoteFetchCompletionBlock completionBlock;
	__unsafe_unretained GTRemoteFetchUpdateTipsBlock updateTipsBlock;
} GTRemoteFetchInfo;

static int fetch_cred_acquire_cb(git_cred **cred, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload) {
	GTRemoteFetchInfo *info = (GTRemoteFetchInfo *)payload;

	if (info->credBlock == nil) {
		NSString *errorMsg = [NSString stringWithFormat:@"No credential block passed, but authentication was requested for remote %@", info->myself.name];
		giterr_set_str(GIT_EUSER, errorMsg.UTF8String);
		return GIT_ERROR;
	}

	return info->credBlock(cred, (GTCredentialType)allowed_types, @(url), @(username_from_url));
}

static void fetch_progress(const char *str, int len, void *payload) {
	GTRemoteFetchInfo *info = (GTRemoteFetchInfo *)payload;

	if (info->progressBlock == nil) return;

	BOOL stop = NO;
	info->progressBlock(@(str), len, &stop);
	if (stop == YES) git_remote_stop(info->myself.git_remote);
}

static int fetch_completion(git_remote_completion_type type, void *payload) {
	GTRemoteFetchInfo *info = (GTRemoteFetchInfo *)payload;

	if (info->completionBlock == nil) return GIT_OK;

	BOOL stop = NO;
	return info->completionBlock((GTRemoteCompletionType)type, &stop);
	if (stop == YES) git_remote_stop(info->myself.git_remote);
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

	BOOL stop = NO;
	int result = info->updateTipsBlock(ref, oid_a, oid_b, &stop);
	if (stop == YES) git_remote_stop(info->myself.git_remote);

	return result;
}

- (BOOL)fetchWithError:(NSError **)error credentials:(GTCredentialAcquireBlock)credBlock progress:(GTRemoteFetchProgressBlock)progressBlock completion:(GTRemoteFetchCompletionBlock)completionBlock updateTips:(GTRemoteFetchUpdateTipsBlock)updateTipsBlock {
	@synchronized (self) {
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
			goto error;
		}

		git_remote_set_cred_acquire_cb(self.git_remote, fetch_cred_acquire_cb, (__bridge void *)(self));

		gitError = git_remote_connect(self.git_remote, GIT_DIRECTION_FETCH);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to connect remote"];
			goto error;
		}

		gitError = git_remote_download(self.git_remote, NULL, NULL);
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
		git_remote_set_callbacks(self.git_remote, NULL);
		git_remote_set_cred_acquire_cb(self.git_remote, NULL, NULL);

		return gitError == GIT_OK;
	}
}

- (void)cancelOperation {
	git_remote_stop(self.git_remote);
}

- (BOOL)isConnected {
	return (BOOL)git_remote_connected(self.git_remote) == 0;
}

@end
