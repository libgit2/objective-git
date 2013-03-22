//
//  GTTestCase.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/22/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTTestCase.h"
#import "GTRepository.h"

static const NSInteger GTTestCaseErrorUnzipFailed = 666;

static NSString * const GTTestCaseErrorDomain = @"com.objectivegit.GTTestCase";

@interface GTTestCase ()
@property (nonatomic, readonly, copy) NSString *repositoryFixturesPath;
@property (nonatomic, copy) NSString *tempDirectoryPath;
@end

@implementation GTTestCase

#pragma mark Setup/Teardown

- (void)SPT_tearDown {
	[self cleanUp];
}

- (void)tearDown {
	[super tearDown];

	[self cleanUp];
}

- (void)cleanUp {
	NSString *path = _tempDirectoryPath;
	if (path == nil) return;

	// Because view model, etc. bindings may persist longer than the test just
	// run (due to crazy Specta/Expecta memory management), we need to wait to
	// remove repositories from disk, or else random tests might start throwing
	// spurious errors.
	atexit_b(^{
		// Don't really care about errors at this point.
		[NSFileManager.defaultManager removeItemAtPath:path error:NULL];
	});

	self.tempDirectoryPath = nil;
}

#pragma mark Fixtures

- (void)setupTempDirectoryPath {
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	NSString *uuidString = CFBridgingRelease(CFUUIDCreateString(NULL, uuidRef));
	CFRelease(uuidRef);

	self.tempDirectoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:uuidString];

	NSFileManager *fileManager = [[NSFileManager alloc] init];
	NSError *error = nil;
	BOOL success = [fileManager createDirectoryAtPath:self.tempDirectoryPath withIntermediateDirectories:YES attributes:nil error:&error];
	STAssertTrue(success, @"Couldn't create the temp fixtures directory at %@: %@", self.tempDirectoryPath, error);
}

- (void)setUpRepositoryFixtureIfNeeded:(NSString *)repositoryName {
	NSString *path = [self.repositoryFixturesPath stringByAppendingPathComponent:repositoryName];

	BOOL isDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) return;

	NSError *error = nil;
	BOOL success = [NSFileManager.defaultManager createDirectoryAtPath:self.repositoryFixturesPath withIntermediateDirectories:YES attributes:nil error:&error];
	STAssertTrue(success, @"Couldn't create the repository fixtures directory at %@: %@", self.repositoryFixturesPath, error);

	NSString *zippedRepositoriesPath = [[self.mainTestBundle.resourcePath stringByAppendingPathComponent:@"fixtures"] stringByAppendingPathComponent:@"fixtures.zip"];

	error = nil;
	success = [self unzipFile:repositoryName fromArchiveAtPath:zippedRepositoriesPath intoDirectory:self.repositoryFixturesPath error:&error];
	STAssertTrue(success, @"Couldn't unzip fixture \"%@\" from %@ to %@: %@", repositoryName, zippedRepositoriesPath, self.repositoryFixturesPath, error);
}

- (NSString *)uniqueString {
	CFUUIDRef uuidRef = CFUUIDCreate(NULL);
	NSString *uuidString = CFBridgingRelease(CFUUIDCreateString(NULL, uuidRef));
	CFRelease(uuidRef);

	return uuidString;
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

- (GTRepository *)fixtureRepositoryNamed:(NSString *)name {
	GTRepository *repository = [[GTRepository alloc] initWithURL:[NSURL fileURLWithPath:[self pathForFixtureRepositoryNamed:name]] error:NULL];
	STAssertNotNil(repository, @"Couldn't create a repository for %@", name);
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

- (NSString *)repositoryFixturesPath {
	return [self.tempDirectoryPath stringByAppendingPathComponent:@"repositories"];
}

@end
