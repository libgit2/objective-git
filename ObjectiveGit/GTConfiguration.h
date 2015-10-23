//
//  GTConfiguration.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/30/11.
//  Copyright (c) 2011 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/types.h"

@class GTRemote;
@class GTRepository;
@class GTSignature;

NS_ASSUME_NONNULL_BEGIN

@interface GTConfiguration : NSObject

@property (nonatomic, readonly, strong, nullable) GTRepository *repository;
@property (nonatomic, readonly, copy) NSArray<NSString *> *configurationKeys;

/// The GTRemotes in the config. If the configuration isn't associated with any
/// repository, this will always be nil.
@property (nonatomic, readonly, copy, nullable) NSArray<GTRemote *> *remotes;

- (instancetype)init NS_UNAVAILABLE;

/// Creates and returns a configuration which includes the global, XDG, and
/// system configurations.
+ (nullable instancetype)defaultConfiguration;

/// The underlying `git_config` object.
- (git_config *)git_config __attribute__((objc_returns_inner_pointer));

- (void)setString:(NSString *)s forKey:(NSString *)key;
- (nullable NSString *)stringForKey:(NSString *)key;

- (void)setBool:(BOOL)b forKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;

- (void)setInt32:(int32_t)i forKey:(NSString *)key;
- (int32_t)int32ForKey:(NSString *)key;

- (void)setInt64:(int64_t)i forKey:(NSString *)key;
- (int64_t)int64ForKey:(NSString *)key;

- (BOOL)deleteValueForKey:(NSString *)key error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
