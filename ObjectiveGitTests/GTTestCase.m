//
//  GTTestCase.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/22/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTTestCase.h"
#import "GTRepository.h"

#import "SPTSpec.h"

static const NSInteger GTTestCaseErrorUnzipFailed = 666;

static NSString * const GTTestCaseErrorDomain = @"com.objectivegit.GTTestCase";	

@interface GTTestCase ()
@property (nonatomic, readonly, copy) NSString *repositoryFixturesPath;
@property (nonatomic, copy) NSString *tempDirectoryPath;
@end

@implementation GTTestCase

#pragma mark Setup/Teardown

- (void)tearDown {
	[super tearDown];

	[self cleanUp];
}

- (void)cleanUp {
	NSString *path = self.tempDirectoryPath;
	if (path == nil) return;

	expect([NSFileManager.defaultManager removeItemAtPath:path error:NULL]).to.beTruthy();

	self.tempDirectoryPath = nil;
}

#pragma mark Fixtures

- (void)setupTempDirectoryPath {
	self.tempDirectoryPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"com.libgit2.objectivegit"] stringByAppendingPathComponent:NSProcessInfo.processInfo.globallyUniqueString];

	NSError *error = nil;
	BOOL success = [NSFileManager.defaultManager createDirectoryAtPath:self.tempDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error];
	XCTAssertTrue(success, @"Couldn't create the temp fixtures directory at %@: %@", self.tempDirectoryPath, error);
}

- (void)setUpRepositoryFixtureIfNeeded:(NSString *)repositoryName {
	NSString *path = [self.repositoryFixturesPath stringByAppendingPathComponent:repositoryName];

	BOOL isDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) return;

	NSError *error = nil;
	BOOL success = [NSFileManager.defaultManager createDirectoryAtPath:self.repositoryFixturesPath withIntermediateDirectories:YES attributes:nil error:&error];
	XCTAssertTrue(success, @"Couldn't create the repository fixtures directory at %@: %@", self.repositoryFixturesPath, error);

	NSString *zippedRepositoriesPath = [[NSBundle bundleForClass:self.class] pathForResource:@"fixtures" ofType:@"zip"];

	error = nil;
	success = [self unzipFile:repositoryName fromArchiveAtPath:zippedRepositoriesPath intoDirectory:self.repositoryFixturesPath error:&error];
	XCTAssertTrue(success, @"Couldn't unzip fixture \"%@\" from %@ to %@: %@", repositoryName, zippedRepositoriesPath, self.repositoryFixturesPath, error);
}

- (NSString *)pathForFixtureRepositoryNamed:(NSString *)repositoryName {
	[self setUpRepositoryFixtureIfNeeded:repositoryName];

	return [self.repositoryFixturesPath stringByAppendingPathComponent:repositoryName];
}

- (BOOL)unzipFile:(NSString *)member fromArchiveAtPath:(NSString *)zipPath intoDirectory:(NSString *)destinationPath error:(NSError **)error {
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = @"/usr/bin/unzip";
	task.arguments = @[ @"-qq", @"-d", destinationPath, zipPath, [member stringByAppendingString:@"*"] ];

	[task launch];
	[task waitUntilExit];

	BOOL success = (task.terminationStatus == 0);
	if (!success) {
		if (error != NULL) *error = [NSError errorWithDomain:GTTestCaseErrorDomain code:GTTestCaseErrorUnzipFailed userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Unzip failed", @"") }];
	}

	return success;
}

#pragma mark API

- (GTRepository *)fixtureRepositoryNamed:(NSString *)name {
	GTRepository *repository = [[GTRepository alloc] initWithURL:[NSURL fileURLWithPath:[self pathForFixtureRepositoryNamed:name]] error:NULL];
	XCTAssertNotNil(repository, @"Couldn't create a repository for %@", name);
	return repository;
}

- (GTRepository *)testAppFixtureRepository {
	return [self fixtureRepositoryNamed:@"Test_App"];
}

- (GTRepository *)testUnicodeFixtureRepository {
	return [self fixtureRepositoryNamed:@"unicode-files-repo"];
}

- (GTRepository *)bareFixtureRepository {
	return [self fixtureRepositoryNamed:@"testrepo.git"];
}

- (GTRepository *)submoduleFixtureRepository {
	return [self fixtureRepositoryNamed:@"repo-with-submodule"];
}

- (GTRepository *)conflictedFixtureRepository {
	return [self fixtureRepositoryNamed:@"conflicted-repo"];
}

- (GTRepository *)blankFixtureRepository {
	NSURL *repoURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"blank-repo"];

	GTRepository *repository = [GTRepository initializeEmptyRepositoryAtFileURL:repoURL bare:NO error:NULL];
	XCTAssertNotNil(repository, @"Couldn't create a blank repository");
	return repository;
}

- (GTRepository *)blankBareFixtureRepository {
	NSURL *repoURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"blank-repo.git"];

	GTRepository *repository = [GTRepository initializeEmptyRepositoryAtFileURL:repoURL bare:YES error:NULL];
	XCTAssertNotNil(repository, @"Couldn't create a blank repository");
	return repository;
}

#pragma mark Properties

- (NSBundle *)mainTestBundle {
	return [NSBundle bundleForClass:self.class];
}

- (NSString *)tempDirectoryPath {
	if (_tempDirectoryPath == nil) {
		[self setupTempDirectoryPath];
	}

	return _tempDirectoryPath;
}

- (NSURL *)tempDirectoryFileURL {
	return [NSURL fileURLWithPath:self.tempDirectoryPath isDirectory:YES];
}

- (NSString *)repositoryFixturesPath {
	return [self.tempDirectoryPath stringByAppendingPathComponent:@"repositories"];
}

@end
