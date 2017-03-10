//
//  GTConfiguration+Private.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTConfiguration.h"

@class GTRepository;

@interface GTConfiguration ()

/// Designated initializer.
///
/// config     - The libgit2 config. Cannot be NULL.
/// repository - The repository in which the config resides. May be nil.
///
/// Returns the initialized object.
- (instancetype _Nullable)initWithGitConfig:(git_config * _Nonnull)config repository:(GTRepository * _Nullable)repository NS_DESIGNATED_INITIALIZER;

@end
