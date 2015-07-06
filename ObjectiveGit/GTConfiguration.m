//
//  GTConfiguration.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/30/11.
//  Copyright (c) 2011 GitHub, Inc. All rights reserved.
//

#import "GTConfiguration.h"
#import "GTConfiguration+Private.h"
#import "GTRepository.h"
#import "GTRemote.h"
#import "GTSignature.h"
#import "NSData+Git.h"
#import "NSError+Git.h"

#import "git2/config.h"
#import "git2/errors.h"
#import "git2/buffer.h"

@interface GTConfiguration ()
@property (nonatomic, readonly, assign) git_config *git_config;
@end

@implementation GTConfiguration

#pragma mark Lifecycle

- (void)dealloc {
	if (_git_config != NULL) {
		git_config_free(_git_config);
		_git_config = NULL;
	}
}

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

- (instancetype)initWithGitConfig:(git_config *)config repository:(GTRepository *)repository {
	NSParameterAssert(config != NULL);

	self = [super init];
	if (self == nil) return nil;

	_git_config = config;
	_repository = repository;

	return self;
}

+ (instancetype)defaultConfiguration {
	git_config *config = NULL;
	int error = git_config_open_default(&config);
	if (error != GIT_OK || config == NULL) return nil;

	return [[self alloc] initWithGitConfig:config repository:nil];
}

#pragma mark Read/Write

- (void)setString:(NSString *)s forKey:(NSString *)key {
	git_config_set_string(self.git_config, key.UTF8String, s.UTF8String);
}

- (NSString *)stringForKey:(NSString *)key {
	git_buf buffer = {};
	if (git_config_get_string_buf(&buffer, self.git_config, key.UTF8String) != 0) return nil;

	return [[NSString alloc] initWithData:[NSData git_dataWithBuffer:&buffer] encoding:NSUTF8StringEncoding];
}

- (void)setBool:(BOOL)b forKey:(NSString *)key {
	git_config_set_bool(self.git_config, key.UTF8String, b);
}

- (BOOL)boolForKey:(NSString *)key {
	int b = 0;
	git_config_get_bool(&b, self.git_config, key.UTF8String);
	return (BOOL) b;
}

- (void)setInt32:(int32_t)i forKey:(NSString *)key {
	git_config_set_int32(self.git_config, key.UTF8String, i);
}

- (int32_t)int32ForKey:(NSString *)key {
	int32_t i = 0;
	git_config_get_int32(&i, self.git_config, key.UTF8String);

	return i;
}

- (void)setInt64:(int64_t)i forKey:(NSString *)key {
	git_config_set_int64(self.git_config, key.UTF8String, i);
}

- (int64_t)int64ForKey:(NSString *)key {
	int64_t i = 0;
	git_config_get_int64(&i, self.git_config, key.UTF8String);

	return i;
}

- (BOOL)deleteValueForKey:(NSString *)key error:(NSError **)error {
	git_config_delete_entry(self.git_config, key.UTF8String);

	return YES;
}

static int configCallback(const git_config_entry *entry, void *payload) {
	NSMutableArray *configurationKeysArray = (__bridge NSMutableArray *)payload;

	[configurationKeysArray addObject:@(entry->name)];

	return 0;
}

- (NSArray *)configurationKeys {
	NSMutableArray *output = [NSMutableArray array];

	git_config_foreach(self.git_config, configCallback, (__bridge void *)output);

	return output;
}

- (NSArray *)remotes {
	GTRepository *repository = self.repository;
	if (repository == nil) return nil;

	git_strarray names;
	git_remote_list(&names, repository.git_repository);
	NSMutableArray *remotes = [NSMutableArray arrayWithCapacity:names.count];
	for (size_t i = 0; i < names.count; i++) {
		const char *name = names.strings[i];
		git_remote *remote = NULL;

		if (git_remote_lookup(&remote, repository.git_repository, name) == 0) {
			[remotes addObject:[[GTRemote alloc] initWithGitRemote:remote inRepository:repository]];
		}
	}

	git_strarray_free(&names);

	return remotes;
}

@end
