//
//  GTIndexTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
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

#import "Contants.h"


@interface GTIndexTest : GHTestCase {
	
	GTIndex *index;
	GTIndex *wIndex;
	NSURL *tempPath;
}
@end

@implementation GTIndexTest

- (void)setUp {
	
	NSError *error = nil;
	index = [GTIndex indexWithPath:[NSURL fileURLWithPath:TEST_INDEX_PATH()] error:&error];
	BOOL success = [index refreshWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanCountIndexEntries {
	
	GHAssertEquals(2, (int)index.entryCount, nil);
}

- (void)testCanClearInMemoryIndex {
	
	[index clear];
	GHAssertEquals(0, (int)index.entryCount, nil);
}

- (void)testCanGetAllDataFromAnEntry {
	
	GTIndexEntry *e = [index getEntryAtIndex:0];
	
	GHAssertNotNil(e, nil);
	GHAssertEqualStrings(@"README", e.path, nil);
	GHAssertEqualStrings(@"1385f264afb75a56a5bec74243be9b367ba4ca08", e.sha, nil);
	GHAssertEquals(1273360380, (int)[e.modificationDate timeIntervalSince1970], nil);
	GHAssertEquals(1273360380, (int)[e.creationDate timeIntervalSince1970], nil);
	GHAssertEquals((long long)4, e.fileSize, nil);
	GHAssertEquals((NSUInteger)234881026, e.dev, nil);
	GHAssertEquals((NSUInteger)6674088, e.ino, nil);
	GHAssertEquals((NSUInteger)33188, e.mode, nil);
	GHAssertEquals((NSUInteger)501, e.uid, nil);
	GHAssertEquals((NSUInteger)0, e.gid, nil);
	GHAssertEquals((NSUInteger)6, e.flags, nil);
	GHAssertFalse(e.isValid, nil);
	GHAssertEquals((NSUInteger)0, e.stage, nil);
	
	e = [index getEntryAtIndex:1];
	GHAssertEqualStrings(@"new.txt", e.path, nil);
	GHAssertEqualStrings(@"fa49b077972391ad58037050f2a75f74e3671e92", e.sha	, nil);
}

- (GTIndexEntry *)createNewIndexEntry {
	
	NSError *error = nil;
	NSDate *now = [NSDate date];
	GTIndexEntry *e = [[[GTIndexEntry alloc] init] autorelease];
	e.path = @"new_path";
	BOOL success = [e setSha:@"d385f264afb75a56a5bec74243be9b367ba4ca08" error:&error];
	GHAssertTrue(success, [error localizedDescription]);
	e.modificationDate = now;
	e.creationDate = now;
	e.fileSize = 1000;
	e.dev = 234881027;
	e.ino = 88888;
	e.mode = 33199;
	e.uid = 502;
	e.gid = 502;
	e.stage = 3;
	
	return e;
}

- (void)testCanSetFlags {
	
	GTIndexEntry *e = [self createNewIndexEntry];
	e.flags = 0;
	GHAssertEquals((NSUInteger)0, e.flags, nil);
	
	NSError *error = nil;
	e.stage = 3;
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEquals((NSUInteger)12288, e.flags, nil);
	
	e.flags = e.flags | GIT_IDXENTRY_VALID;
	GHAssertTrue([e isValid], nil);
}

- (void)testCanUpdateEntries {
	
	NSError *error = nil;
	NSDate *now = [NSDate date];
	GTIndexEntry *e = [index getEntryAtIndex:0];
	
	e.path = @"new_path";
	BOOL success = [e setSha:@"12ea3153a78002a988bb92f4123e7e831fd1138a" error:&error];
	GHAssertTrue(success, [error localizedDescription]);
	e.modificationDate = now;
	e.creationDate = now;
	e.fileSize = 1000;
	e.dev = 234881027;
	e.ino = 88888;
	e.mode = 33199;
	e.uid = 502;
	e.gid = 502;
	e.flags = 234;
	
	GHAssertEqualStrings(@"new_path", e.path, nil);
	GHAssertEqualStrings(@"12ea3153a78002a988bb92f4123e7e831fd1138a", e.sha, nil);
	GHAssertEquals((int)[now timeIntervalSince1970], (int)[e.modificationDate timeIntervalSince1970], nil);
	GHAssertEquals((int)[now timeIntervalSince1970], (int)[e.creationDate timeIntervalSince1970], nil);
	GHAssertEquals((long long)1000, e.fileSize, nil);
	GHAssertEquals((NSUInteger)234881027, e.dev, nil);
	GHAssertEquals((NSUInteger)88888, e.ino, nil);
	GHAssertEquals((NSUInteger)33199, e.mode, nil);
	GHAssertEquals((NSUInteger)502, e.uid, nil);
	GHAssertEquals((NSUInteger)502, e.gid, nil);
	GHAssertEquals((NSUInteger)234, e.flags, nil);
}

- (void)testCanAddNewEntries {
	
	NSError *error = nil;
	GTIndexEntry *e = [self createNewIndexEntry];
	
	BOOL success = [index addEntry:e error:&error];
	
	GHAssertTrue(success, [error localizedDescription]);
	GHAssertEquals(3, (int)[index entryCount], nil);
	e = [index getEntryAtIndex:2];
	GHAssertEqualStrings(@"new_path", e.path, nil);
}


- (void)createTempPath {
	
    NSError *error = nil;
    NSFileManager *m = [[[NSFileManager alloc] init] autorelease];
    tempPath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"index"]];	
	
    if([m fileExistsAtPath:[tempPath path]])
		[m removeItemAtURL:tempPath error:&error];
	
	[m copyItemAtURL:[NSURL fileURLWithPath:TEST_INDEX_PATH()] toURL:tempPath error:&error];
    GHAssertNil(error, [error localizedDescription]);
	
	wIndex = [GTIndex indexWithPath:tempPath error:&error];
	GHAssertNil(error, [error localizedDescription]);
	BOOL success = [wIndex refreshWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanWriteNewIndex {
	
	NSError *error = nil;
	[self createTempPath];
	GTIndexEntry *e = [self createNewIndexEntry];
	BOOL success = [wIndex addEntry:e error:&error];
	GHAssertTrue(success, [error localizedDescription]);
	
	e.path = @"else.txt";
	success = [wIndex addEntry:e error:&error];
	GHAssertTrue(success, [error localizedDescription]);
	success = [wIndex writeWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
	
	GTIndex *index2 = [GTIndex indexWithPath:tempPath error:&error];
	GHAssertNil(error, [error localizedDescription]);
	success = [index2 refreshWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
	GHAssertEquals(4, (int)[index2 entryCount], nil);
}

- (void)testCanAddFromAPath {
#ifndef TARGET_OS_IPHONE
	//setup
	NSError *error = nil;
	NSFileManager *m = [[[NSFileManager alloc] init] autorelease];
	tempPath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"index_dir"]];
	NSURL *repoPath = [tempPath URLByAppendingPathComponent:@".git"];
	
	[m removeItemAtPath:[tempPath path] error:&error];
	GHAssertTrue([m createDirectoryAtPath:[tempPath path] withIntermediateDirectories:YES attributes:nil error:&error], [error localizedDescription]);
	
	// run 'git init'
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/local/bin/git"];
	[task setCurrentDirectoryPath:[tempPath path]];
	[task setArguments:[NSArray arrayWithObjects:@"init", nil]];
	[task launch];
	[task waitUntilExit];
	GHAssertTrue([task terminationStatus] == 0, @"git init failed");
	
	// create a new file in working dir
	NSURL *file = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"index_dir/test.txt"]];
	[@"test content" writeToURL:file atomically:NO encoding:NSUTF8StringEncoding error:&error];
	
	// open the repo and write to the index
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:repoPath error:&error];
	GHAssertNotNil(repo, [error localizedDescription]);
	BOOL success = [repo setupIndexAndReturnError:&error];
	GHAssertTrue(success, [error localizedDescription]);
	success = [repo.index addFile:[file lastPathComponent] error:&error]; 
	GHAssertTrue(success, [error localizedDescription]);
	success = [repo.index writeAndReturnError:&error]; 
	GHAssertTrue(success, [error localizedDescription]);
	
	GTIndex *index2 = [GTIndex indexWithPath:[tempPath URLByAppendingPathComponent:@".git/index"] error:&error];
	success = [index2 refreshAndReturnError:&error];
	GHAssertTrue(success, [error localizedDescription]);
	
	GHAssertEqualStrings([index2 getEntryAtIndex:0].path, @"test.txt", nil);
#endif
}

@end
