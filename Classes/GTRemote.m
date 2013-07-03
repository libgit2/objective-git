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

	return self;
}

- (id)initWithGitRemote:(git_remote *)remote {
	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;

	return self;
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

static int fetch_cred_acquire_cb(git_cred **cred, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload) {
	GTRemote *myself = (__bridge GTRemote *)payload;
	NSLog(@"fetch_cred_acquire_cb: %@: url: %s, username: %s, types: %d", myself, url, username_from_url, allowed_types);
	switch (allowed_types) {
		case GIT_CREDTYPE_USERPASS_PLAINTEXT:
			break;
		case GIT_CREDTYPE_SSH_KEYFILE_PASSPHRASE:
			break;
		case GIT_CREDTYPE_SSH_PUBLICKEY:
			break;
	}
	return GIT_OK;
}

static void fetch_progress(const char *str, int len, void *data) {
	GTRemote *myself = (__bridge GTRemote *)data;
	NSLog(@"fetch_progress: %@: str: %s, len: %d", myself, str, len);
}

static int fetch_completion(git_remote_completion_type type, void *data) {
	GTRemote *myself = (__bridge GTRemote *)data;
	NSLog(@"fetch_completion: %@: %d", myself, type);
	return GIT_OK;
}

static int fetch_update_tips(const char *refname, const git_oid *a, const git_oid *b, void *data) {
	GTRemote *myself = (__bridge GTRemote *)data;
	GTOID *oid_a = [[GTOID alloc] initWithGitOid:a];
	GTOID *oid_b = [[GTOID alloc] initWithGitOid:b];
	NSLog(@"fetch_update_tips: %@: refname: %s, OID a: %@, b: %@", myself, refname, oid_a, oid_b);
	return GIT_OK;
}

- (BOOL)fetchWithError:(NSError **)error {
	git_remote_callbacks remote_callbacks = GIT_REMOTE_CALLBACKS_INIT;
	remote_callbacks.progress = fetch_progress;
	remote_callbacks.completion = fetch_completion;
	remote_callbacks.update_tips = fetch_update_tips;
	remote_callbacks.payload = (__bridge void *)(self);

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

@end
