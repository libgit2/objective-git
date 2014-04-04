//
//  GTRepository+Reset.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

@interface GTRepository (Reset)

/// Reset the repository's HEAD to the given commit.
///
/// commit    - The commit the HEAD is to be reset to. Must not be nil.
/// resetType - The type of reset to be used.
/// error     - The error if one occurred.
///
/// Returns whether the reset was succcessful.
- (BOOL)resetToCommit:(GTCommit *)commit withResetType:(GTRepositoryResetType)resetType error:(NSError **)error;

/// Resets the give paths in the index to the tree entries from the commit.
///
/// paths  - The paths to reset. Cannot be nil.
/// commit - The commit whose tree should be used to reset. Cannot be nil.
/// error  - The error if one occurred.
///
/// Returns whether the reset was successful.
- (BOOL)resetPaths:(NSArray *)paths toCommit:(GTCommit *)commit error:(NSError **)error;

@end
