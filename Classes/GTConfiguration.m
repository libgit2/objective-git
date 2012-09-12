//
//  GTConfiguration.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/30/11.
//  Copyright (c) 2011 GitHub, Inc. All rights reserved.
//

#import "GTConfiguration.h"
#import "GTRepository.h"

@implementation GTConfiguration

- (void)dealloc {
	git_config_free(self.git_config);
}

#pragma mark API

- (id)initWithGitConfig:(git_config *)config repository:(GTRepository *)repository {
	self = [super init];
	if (self == nil) return nil;

	_git_config = config;
	_repository = repository;

	return self;
}

- (void)setString:(NSString *)s forKey:(NSString *)key {
	git_config_set_string(self.git_config, key.UTF8String, s.UTF8String);
}

- (NSString *)stringForKey:(NSString *)key {
	const char *string = NULL;
	git_config_get_string(&string, self.git_config, key.UTF8String);
	if (string == NULL) return nil;

	return [NSString stringWithUTF8String:string];
}

- (void)setBoolForKey:(BOOL)b forKey:(NSString *)key {
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
	git_config_delete(self.git_config, key.UTF8String);

	return YES;
}

- (void)addRemote:(NSString *)remoteName withCloneURL:(NSURL *)cloneURL {
    // TODO: implement something useful to the libgit2 project to make these remote / branch
    // names easier to construct. See:
    // <https://github.com/libgit2/libgit2/issues/161>
    // <https://github.com/libgit2/libgit2/issues/160>
    //
    // for now, this implementation wraps away the lack of a lower level API

    [self setString:[NSString stringWithFormat:@"+refs/heads/*:refs/remotes/%@/*", remoteName] forKey:[NSString stringWithFormat:@"remote \"%@\".fetch", remoteName]];
    [self setString:[cloneURL absoluteString] forKey:[NSString stringWithFormat:@"remote \"%@\".url", remoteName]];
}

- (void)addBranch:(NSString *)branchName trackingRemoteName:(NSString *)remoteName {
    [self setString:[NSString stringWithFormat:@"refs/heads/%@", branchName] forKey:[NSString stringWithFormat:@"branch \"%@\".merge", branchName]];

    if(remoteName != nil) {
        [self setString:remoteName forKey:[NSString stringWithFormat:@"branch \"%@\".remote", branchName]];
	}
}

int configCallback(const char* name, const char* value, void* payload);
int configCallback(const char* name, const char* value, void* payload) {
    NSMutableArray* configurationKeysArray = (__bridge NSMutableArray*)(payload);

    [configurationKeysArray addObject: [NSString stringWithCString: name encoding: [NSString defaultCStringEncoding]]];

    return 0;
}

- (NSArray*) configurationKeys {
    NSMutableArray* output = [NSMutableArray array];

    git_config_foreach(self.git_config, configCallback, (__bridge void*)(output));
    return (output);

}
@end
