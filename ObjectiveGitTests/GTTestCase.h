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

BOOL unzipFileFromArchiveAtPathIntoDirectory(NSString *fileName, NSString *zipPath, NSString *destinationPath);
NSString *repositoryFixturePathForName(NSString *repositoryName, Class cls);
BOOL setupRepositoryFixtureIfNeeded(NSString *repositoryName, Class cls);
NSString *TEST_REPO_PATH(Class cls);
NSString *TEST_INDEX_PATH(Class cls);
NSString *TEST_APP_REPO_PATH(Class cls);
void rm_loose(Class cls, NSString *sha);

@interface GTTestCase : SPTSenTestCase

// The file URL for a temporary directory which will live for the length of each
// example (`it`).
@property (nonatomic, readonly, strong) NSURL *tempDirectoryFileURL;

// Find and return the fixture repository with the given name;
- (GTRepository *)fixtureRepositoryNamed:(NSString *)name;

@end
