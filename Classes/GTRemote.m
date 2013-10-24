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

#import "NSError+Git.h"
#import "EXTScope.h"

@interface GTRemote ()

@property (nonatomic, readonly, assign) git_remote *git_remote;
@property (nonatomic, strong) GTRepository *repository;
@end

@implementation GTRemote

#pragma mark Lifecycle

- (id)initWithGitRemote:(git_remote *)remote {
	NSParameterAssert(remote != NULL);

	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;

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

+ (instancetype)createRemoteWithName:(NSString *)name url:(NSString *)URL inRepository:(GTRepository *)repo error:(NSError **)error {
	NSParameterAssert(name != nil);
	NSParameterAssert(URL != nil);
	NSParameterAssert(repo != nil);

	git_remote *remote;
	int gitError = git_remote_create(&remote, repo.git_repository, name.UTF8String, URL.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Remote creation failed" failureReason:nil];

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

- (id)initWithGitRemote:(git_remote *)remote inRepository:(GTRepository *)repo {
	NSParameterAssert(remote != NULL);
	NSParameterAssert(repo != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;

	_repository = repo;

	return self;
}

#pragma mark Properties

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

- (BOOL)isConnected {
	return git_remote_connected(self.git_remote) == 0;
}

#pragma mark Renaming

typedef int (^GTRemoteRenameBlock)(NSString *refspec);

typedef struct {
	__unsafe_unretained GTRemote *myself;
	__unsafe_unretained GTRemoteRenameBlock renameBlock;
} GTRemoteRenameInfo;

static int remote_rename_problem_cb(const char *problematic_refspec, void *payload) {
	GTRemoteRenameInfo *info = payload;
	if (info->renameBlock == nil) return GIT_ERROR;

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

- (NSArray *)fetchRefspecs {
	__block git_strarray refspecs;
	int gitError = git_remote_get_fetch_refspecs(&refspecs, self.git_remote);
	if (gitError != GIT_OK) return nil;

	@onExit {
		git_strarray_free(&refspecs);
	};

	NSMutableArray *fetchRefspecs = [NSMutableArray arrayWithCapacity:refspecs.count];
	for (size_t i = 0; i < refspecs.count; i++) {
		if (refspecs.strings[i] == NULL) continue;
		[fetchRefspecs addObject:@(refspecs.strings[i])];
	}
	return [fetchRefspecs copy];
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

- (BOOL)removeFetchRefspec:(NSString *)fetchRefspec error:(NSError **)error {
	NSParameterAssert(fetchRefspec != nil);

	NSUInteger index = [self.fetchRefspecs indexOfObject:fetchRefspec];
	if (index == NSNotFound) return YES;

	int gitError = git_remote_remove_refspec(self.git_remote, index);
	if (gitError != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Unable to remove fetch refspec."];
		}
		return NO;
	}
	return [self saveRemote:error];
}


#pragma mark Fetch

typedef void (^GTRemoteTransferProgressBlock)(const git_transfer_progress *stats, BOOL *stop);

typedef struct {
	// WARNING: Provider must come first to be layout-compatible with GTCredentialAcquireCallbackInfo
	__unsafe_unretained GTCredentialProvider *credProvider;
	__unsafe_unretained GTRemoteTransferProgressBlock progressBlock;
	git_direction direction;
} GTRemoteConnectionInfo;

int transfer_progress_cb(const git_transfer_progress *stats, void *payload) {
	GTRemoteConnectionInfo *info = payload;
	BOOL stop = NO;

	info->progressBlock(stats, &stop);

	return (stop ? -1 : 0);
}

- (BOOL)connectRemoteWithInfo:(GTRemoteConnectionInfo *)info error:(NSError **)error block:(BOOL (^)(NSError **error))connectedBlock {
	git_remote_set_cred_acquire_cb(self.git_remote, GTCredentialAcquireCallback, &info);

	int gitError = git_remote_connect(self.git_remote, info->direction);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to connect remote"];
		return NO;
	}

	BOOL success = connectedBlock(error);
	if (success != YES) return NO;

	git_remote_disconnect(self.git_remote);
	git_remote_set_cred_acquire_cb(self.git_remote, NULL, NULL);

	return YES;
}

- (BOOL)fetchWithCredentialProvider:(GTCredentialProvider *)credProvider error:(NSError **)error progress:(GTRemoteTransferProgressBlock)progressBlock {
	@synchronized (self) {
		__block GTRemoteConnectionInfo connectionInfo = {
			.credProvider = credProvider,
			.progressBlock = progressBlock,
			.direction = GIT_DIRECTION_FETCH,
		};

		BOOL success = [self connectRemoteWithInfo:&connectionInfo error:error block:^BOOL(NSError **error){
			int gitError = git_remote_download(self.git_remote, (progressBlock != nil ? transfer_progress_cb : NULL), &connectionInfo);
			if (gitError != GIT_OK) {
				if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to fetch remote"];
				return NO;
			}

			gitError = git_remote_update_tips(self.git_remote);
			if (gitError != GIT_OK) {
				if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to update tips"];
				return NO;
			}
			return YES;
		}];

		return success;
	}
}

#pragma mark -
#pragma mark Push

- (BOOL)pushReferences:(NSArray *)references credentialProvider:(GTCredentialProvider *)credProvider error:(NSError **)error {
	NSParameterAssert(references != nil);

	git_push *push;
	int gitError = git_push_new(&push, self.git_remote);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Push object creation failed" failureReason:@"Failed to create push object for references %@", [references componentsJoinedByString:@", "]];
		return NO;
	}
	@onExit {
		git_push_free(push);
	};

	for (id reference in references) {
		NSString *name = nil;
		if ([reference isKindOfClass:[NSString class]]) {
			name = reference;
		} else if ([reference isKindOfClass:[GTReference class]]) {
			name = [(GTReference *)reference name];
		}
		NSAssert(name != nil, @"Invalid reference passed: %@", reference);

		gitError = git_push_add_refspec(push, name.UTF8String);
		if (gitError != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Adding reference failed" failureReason:@"Failed to add reference \"%@\" to push object", reference];
			return NO;
		}
	}

	@synchronized (self) {
		GTRemoteConnectionInfo connectionInfo = {
			.credProvider = credProvider,
			.direction = GIT_DIRECTION_PUSH,
		};
		BOOL success = [self connectRemoteWithInfo:&connectionInfo error:error block:^BOOL(NSError **error) {
			int gitError = git_push_finish(push);
			if (gitError != GIT_OK) {
				if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Push to remote failed"];
				return NO;
			}

			gitError = git_push_unpack_ok(push);
			if (gitError != GIT_OK) {
				if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Unpacking failed"];
				return NO;
			}

			gitError = git_push_update_tips(push);
			if (gitError != GIT_OK) {
				if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Update tips failed"];
				return NO;
			}

			/* TODO: libgit2 sez we should check git_push_status_foreach to see if our push succeeded */
			return YES;
		}];
		
		return success;
	}
}

@end
