//
//  GTConfiguration.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/30/11.
//  Copyright (c) 2011 GitHub, Inc. All rights reserved.
//

#include "git2.h"

@class GTRepository;

@interface GTConfiguration : NSObject

@property (nonatomic, readonly, assign) git_config *git_config;
@property (nonatomic, readonly, unsafe_unretained) GTRepository *repository;
@property (nonatomic, readonly, copy) NSArray *configurationKeys;

// The GTRemotes in the config. If the configuration isn't associated with any
// repository, this will always be nil.
@property (nonatomic, readonly, copy) NSArray *remotes;

// Creates and returns a configuration which includes the global, XDG, and
// system configurations.
+ (instancetype)defaultConfiguration;

- (void)setString:(NSString *)s forKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;

- (void)setBoolForKey:(BOOL)b forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;

- (void)setInt32:(int32_t)i forKey:(NSString *)key;
- (int32_t)int32ForKey:(NSString *)key;

- (void)setInt64:(int64_t)i forKey:(NSString *)key;
- (int64_t)int64ForKey:(NSString *)key;

- (BOOL)deleteValueForKey:(NSString *)key error:(NSError **)error;

// Reloads the configuration from the files on disk if they have changed since
// it was originally loaded.
//
// error - The error if one occurred.
//
// Returns whether the refresh was successful.
- (BOOL)refresh:(NSError **)error;

@end
