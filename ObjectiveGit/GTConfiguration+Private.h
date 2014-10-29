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

/// Initializes the receiver.
///
/// config     - The libgit2 config. Cannot be NULL.
/// repository - The repository in which the config resides. May be nil.
///
/// Returns the initialized object.
- (id)initWithGitConfig:(git_config *)config repository:(GTRepository *)repository;

@end
