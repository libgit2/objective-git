//
//  Contants.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/24/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <git2.h>

#import "GTRepository.h"
#import "GTObject.h"
#import "GTObjectDatabase.h"
#import "GTOdbObject.h"
#import "GTCommit.h"
#import "GTSignature.h"
#import "GTTree.h"
#import "GTTreeEntry.h"
#import "GTEnumerator.h"
#import "GTBlob.h"
#import "GTTag.h"
#import "GTIndex.h"
#import "GTIndexEntry.h"
#import "GTReference.h"
#import "GTBranch.h"

static inline BOOL unzipFileFromArchiveAtPathIntoDirectory(NSString *fileName, NSString *zipPath, NSString *destinationPath) {
	NSTask *task = [[NSTask alloc] init];
	task.launchPath = @"/usr/bin/unzip";
	task.arguments = @[ @"-qq", @"-d", destinationPath, zipPath, [fileName stringByAppendingString:@"*"] ];
	
	[task launch];
	[task waitUntilExit];
	
	BOOL success = (task.terminationStatus == 0);
	return success;
}

static inline NSString *repositoryFixturePathForName(NSString *repositoryName, Class cls) {
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

static inline BOOL setupRepositoryFixtureIfNeeded(NSString *repositoryName, Class cls) {
	NSString *path = repositoryFixturePathForName(repositoryName, cls);
	BOOL isDirectory = NO;
	if ([NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory] && isDirectory) return YES;
	
	if (![NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:NULL]) return NO;
	
	NSString *zippedFixturesPath = [[[NSBundle bundleForClass:cls] resourcePath] stringByAppendingPathComponent:@"fixtures/fixtures.zip"];
	return unzipFileFromArchiveAtPathIntoDirectory(repositoryName, zippedFixturesPath, path.stringByDeletingLastPathComponent);
}

static inline NSString *TEST_REPO_PATH(Class cls) {
	if (!setupRepositoryFixtureIfNeeded(@"testrepo.git", cls)) {
		NSLog(@"Failed to unzip fixtures.");
	}
		
	return repositoryFixturePathForName(@"testrepo.git", cls);
}

static inline NSString *TEST_INDEX_PATH(Class cls) {
	return [TEST_REPO_PATH(cls) stringByAppendingPathComponent:@"index"];
}

static inline NSString *TEST_APP_REPO_PATH(Class cls) {
	if (!setupRepositoryFixtureIfNeeded(@"Test_App", cls)) {
		NSLog(@"Failed to unzip fixtures.");
	}
	return repositoryFixturePathForName(@"Test_App", cls);
}

static inline void rm_loose(Class cls, NSString *sha) {
	
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
