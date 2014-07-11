//
//  GTTestCase.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/22/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#define SPT_SUBCLASS GTTestCase
#import "Specta.h"

@class GTRepository;

@interface GTTestCase : SPTXCTestCase

// The file URL for a temporary directory which will live for the length of each
// example (`it`).
@property (nonatomic, readonly, strong) NSURL *tempDirectoryFileURL;

// A fully fledged repository, great for testing nearly everything.
- (GTRepository *)testAppFixtureRepository;

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
