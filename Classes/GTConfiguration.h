//
//  GTConfiguration.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/30/11.
//  Copyright (c) 2011 GitHub, Inc. All rights reserved.
//

#include "git2.h"


@interface GTConfiguration : NSObject

@property (nonatomic, readonly, assign) git_config *git_config;

+ (GTConfiguration *)configurationWithConfiguration:(git_config *)config;

- (void)setString:(NSString *)s forKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;

- (void)setBoolForKey:(BOOL)b forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;

- (void)setInt32:(int32_t)i forKey:(NSString *)key;
- (int32_t)int32ForKey:(NSString *)key;

- (void)setInt64:(int64_t)i forKey:(NSString *)key;
- (int64_t)int64ForKey:(NSString *)key;

- (BOOL)deleteValueForKey:(NSString *)key error:(NSError **)error;

- (void)addRemote:(NSString *)remoteName withCloneURL:(NSURL *)cloneURL;
- (void)addBranch:(NSString *)branchName trackingRemoteName:(NSString *)remoteName;

- (NSArray*) configurationKeys;
@end
