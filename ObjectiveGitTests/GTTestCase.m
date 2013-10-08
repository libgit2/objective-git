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

BOOL unzipFileFromArchiveAtPathIntoDirectory(NSString *fileName, NSString *zipPath, NSString *destinationPath) {
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = @"/usr/bin/unzip";
	task.arguments = @[ @"-qq", @"-d", destinationPath, zipPath, [fileName stringByAppendingString:@"*"] ];
	
	[task launch];
	[task waitUntilExit];
	
	BOOL success = (task.terminationStatus == 0);
	return success;
}

NSString *repositoryFixturePathForName(NSString *repositoryName, Class cls) {
	static NSString *unzippedFixturesPath = nil;
	if (unzippedFixturesPath == nil) {
		NSString *containerPath = nil;
		while (containerPath == nil) {
			containerPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"com.libgit2.objectivegit"] stringByAppendingPathComponent:NSProcessInfo.processInfo.globallyUniqueString];
			if ([NSFileManager.defaultManager fileExistsAtPath:containerPath]) containerPath = nil;
		}
		
		unzippedFixturesPath = containerPath;
	}
	
	return [unzippedFixturesPath stringByAppendingPathComponent:repositoryName];
}

BOOL setupRepositoryFixtureIfNeeded(NSString *repositoryName, Class cls) {
	NSString *path = repositoryFixturePathForName(repositoryName, cls);
	BOOL isDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) {
		[NSFileManager.defaultManager removeItemAtPath:path error:NULL];
	}
	
	if (![NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL]) return NO;
	
	NSString *zippedFixturesPath = [[NSBundle bundleForClass:cls] pathForResource:@"fixtures" ofType:@"zip"];
	return unzipFileFromArchiveAtPathIntoDirectory(repositoryName, zippedFixturesPath, path.stringByDeletingLastPathComponent);
}

NSString *TEST_REPO_PATH(Class cls) {
	if (!setupRepositoryFixtureIfNeeded(@"testrepo.git", cls)) {
		NSLog(@"Failed to unzip fixtures.");
	}
		
	return repositoryFixturePathForName(@"testrepo.git", cls);
}

NSString *TEST_INDEX_PATH(Class cls) {
	return [TEST_REPO_PATH(cls) stringByAppendingPathComponent:@"index"];
}

NSString *TEST_APP_REPO_PATH(Class cls) {
	if (!setupRepositoryFixtureIfNeeded(@"Test_App", cls)) {
		NSLog(@"Failed to unzip fixtures.");
	}
	return repositoryFixturePathForName(@"Test_App", cls);
}

void rm_loose(Class cls, NSString *sha) {
	NSError *error;
	NSFileManager *m = [[NSFileManager alloc] init];
	NSString *objDir = [NSString stringWithFormat:@"objects/%@", [sha substringToIndex:2]];
	NSURL *basePath = [[NSURL fileURLWithPath:TEST_REPO_PATH(cls)] URLByAppendingPathComponent:objDir];
	NSURL *filePath = [basePath URLByAppendingPathComponent:[sha substringFromIndex:2]];
	
	NSLog(@"deleting file %@", filePath);
	
	[m removeItemAtURL:filePath error:&error];
	
	NSArray *contents = [m contentsOfDirectoryAtPath:[basePath path] error:&error];
	if([contents count] == 0) {
		NSLog(@"deleting dir %@", basePath);
		[m removeItemAtURL:basePath error:&error];
	}
}

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

	NSString *zippedRepositoriesPath = [[NSBundle bundleForClass:self.class] pathForResource:@"fixtures" ofType:@"zip"];

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

- (NSURL *)tempDirectoryFileURL {
	return [NSURL fileURLWithPath:self.tempDirectoryPath isDirectory:YES];
}

- (NSString *)repositoryFixturesPath {
	return [self.tempDirectoryPath stringByAppendingPathComponent:@"repositories"];
}

@end
