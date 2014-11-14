//
//  QuickSpec+GTFixtures.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/22/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Quick/Quick.h>

@class GTRepository;

// FIXME: This category is a total hack, but there's no other way to run
// teardown logic for every example yet:
// https://github.com/Quick/Quick/issues/163
@interface QuickSpec (GTFixtures)

// The file URL for a temporary directory which will live for the length of each
// example (`it`).
@property (nonatomic, readonly, strong) NSURL *tempDirectoryFileURL;

// A fully fledged repository, great for testing nearly everything.
- (GTRepository *)testAppFixtureRepository;

/// A fork of Test_App.
- (GTRepository *)testAppForkFixtureRepository;

// A bare repository with a minimal history.
- (GTRepository *)bareFixtureRepository;

// A repository which has a submodule.
- (GTRepository *)submoduleFixtureRepository;

// A repository containing conflicts.
- (GTRepository *)conflictedFixtureRepository;

// A pristine repository (bare).
- (GTRepository *)blankBareFixtureRepository;

// A pristine repository.
- (GTRepository *)blankFixtureRepository;

// A repository with unicode files.
- (GTRepository *)testUnicodeFixtureRepository;

@end
