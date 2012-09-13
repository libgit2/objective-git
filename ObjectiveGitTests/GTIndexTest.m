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


@interface GTIndexTest : SenTestCase {
	
	GTIndex *index;
	GTIndex *wIndex;
	NSURL *tempPath;
}
@end

@implementation GTIndexTest

- (void)setUp {
	
	NSError *error = nil;
	index = [GTIndex indexWithFileURL:[NSURL fileURLWithPath:TEST_INDEX_PATH(self.class)] error:&error];
	BOOL success = [index refreshWithError:&error];
	STAssertTrue(success, [error localizedDescription]);
}

- (void)testCanCountIndexEntries {
	
	STAssertEquals(2, (int)index.entryCount, nil);
}

- (void)testCanClearInMemoryIndex {
	
	[index clear];
	STAssertEquals(0, (int)index.entryCount, nil);
}

- (void)testCanGetAllDataFromAnEntry {
	
	GTIndexEntry *e = [index entryAtIndex:0];
	
	STAssertNotNil(e, nil);
	STAssertEqualObjects(@"README", e.path, nil);
	STAssertEqualObjects(@"1385f264afb75a56a5bec74243be9b367ba4ca08", e.sha, nil);
	STAssertEquals(1273360380, (int)[e.modificationDate timeIntervalSince1970], nil);
	STAssertEquals(1273360380, (int)[e.creationDate timeIntervalSince1970], nil);
	STAssertEquals((long long)4, e.fileSize, nil);
	STAssertEquals((NSUInteger)234881026, e.dev, nil);
	STAssertEquals((NSUInteger)6674088, e.ino, nil);
	STAssertEquals((NSUInteger)33188, e.mode, nil);
	STAssertEquals((NSUInteger)501, e.uid, nil);
	STAssertEquals((NSUInteger)0, e.gid, nil);
	STAssertEquals((NSUInteger)6, e.flags, nil);
	STAssertFalse(e.isValid, nil);
	STAssertEquals((NSUInteger)0, e.staged, nil);
	
	e = [index entryAtIndex:1];
	STAssertEqualObjects(@"new.txt", e.path, nil);
	STAssertEqualObjects(@"fa49b077972391ad58037050f2a75f74e3671e92", e.sha	, nil);
}

- (GTIndexEntry *)createNewIndexEntry {
	
	NSError *error = nil;
	NSDate *now = [NSDate date];
	GTIndexEntry *e = [[GTIndexEntry alloc] init];
	e.path = @"new_path";
	BOOL success = [e setSha:@"d385f264afb75a56a5bec74243be9b367ba4ca08" error:&error];
	STAssertTrue(success, [error localizedDescription]);
	e.modificationDate = now;
	e.creationDate = now;
	e.fileSize = 1000;
	e.dev = 234881027;
	e.ino = 88888;
	e.mode = 33199;
	e.uid = 502;
	e.gid = 502;
	
	return e;
}

- (void)testCanSetFlags {
	
	GTIndexEntry *e = [self createNewIndexEntry];
	e.flags = 0;
	STAssertEquals((NSUInteger)0, e.flags, nil);
	
	e.flags = e.flags | GIT_IDXENTRY_VALID;
	STAssertTrue([e isValid], nil);
}

- (void)testCanUpdateEntries {
	
	NSError *error = nil;
	NSDate *now = [NSDate date];
	GTIndexEntry *e = [index entryAtIndex:0];
	
	e.path = @"new_path";
	BOOL success = [e setSha:@"12ea3153a78002a988bb92f4123e7e831fd1138a" error:&error];
	STAssertTrue(success, [error localizedDescription]);
	e.modificationDate = now;
	e.creationDate = now;
	e.fileSize = 1000;
	e.dev = 234881027;
	e.ino = 88888;
	e.mode = 33199;
	e.uid = 502;
	e.gid = 502;
	e.flags = 234;
	
	STAssertEqualObjects(@"new_path", e.path, nil);
	STAssertEqualObjects(@"12ea3153a78002a988bb92f4123e7e831fd1138a", e.sha, nil);
	STAssertEquals((int)[now timeIntervalSince1970], (int)[e.modificationDate timeIntervalSince1970], nil);
	STAssertEquals((int)[now timeIntervalSince1970], (int)[e.creationDate timeIntervalSince1970], nil);
	STAssertEquals((long long)1000, e.fileSize, nil);
	STAssertEquals((NSUInteger)234881027, e.dev, nil);
	STAssertEquals((NSUInteger)88888, e.ino, nil);
	STAssertEquals((NSUInteger)33199, e.mode, nil);
	STAssertEquals((NSUInteger)502, e.uid, nil);
	STAssertEquals((NSUInteger)502, e.gid, nil);
	STAssertEquals((NSUInteger)234, e.flags, nil);
}

- (void)testCanAddNewEntries {
	
	NSError *error = nil;
	GTIndexEntry *e = [self createNewIndexEntry];
	
	BOOL success = [index addEntry:e error:&error];
	
	STAssertTrue(success, [error localizedDescription]);
	STAssertEquals(3, (int)[index entryCount], nil);
	e = [index entryAtIndex:2];
	STAssertEqualObjects(@"new_path", e.path, nil);
}


- (void)createTempPath {
	
    NSError *error = nil;
    NSFileManager *m = [[NSFileManager alloc] init];
    tempPath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"index"]];	
	
    if([m fileExistsAtPath:[tempPath path]])
		[m removeItemAtURL:tempPath error:&error];
	
	[m copyItemAtURL:[NSURL fileURLWithPath:TEST_INDEX_PATH(self.class)] toURL:tempPath error:&error];
    STAssertNil(error, [error localizedDescription]);
	
	wIndex = [GTIndex indexWithFileURL:tempPath error:&error];
	STAssertNil(error, [error localizedDescription]);
	BOOL success = [wIndex refreshWithError:&error];
	STAssertTrue(success, [error localizedDescription]);
}

- (void)testCanWriteNewIndex {
	
	NSError *error = nil;
	[self createTempPath];
	GTIndexEntry *e = [self createNewIndexEntry];
	BOOL success = [wIndex addEntry:e error:&error];
	STAssertTrue(success, [error localizedDescription]);
	
	e.path = @"else.txt";
	success = [wIndex addEntry:e error:&error];
	STAssertTrue(success, [error localizedDescription]);
	success = [wIndex writeWithError:&error];
	STAssertTrue(success, [error localizedDescription]);
	
	GTIndex *index2 = [GTIndex indexWithFileURL:tempPath error:&error];
	STAssertNil(error, [error localizedDescription]);
	success = [index2 refreshWithError:&error];
	STAssertTrue(success, [error localizedDescription]);
	STAssertEquals(4, (int)[index2 entryCount], nil);
}

- (void)testCanAddFromAPath {
#ifndef TARGET_OS_IPHONE
	//setup
	NSError *error = nil;
	NSFileManager *m = [[[NSFileManager alloc] init] autorelease];
	tempPath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"index_dir"]];
	NSURL *repoPath = [tempPath URLByAppendingPathComponent:@".git"];
	
	[m removeItemAtPath:[tempPath path] error:&error];
	STAssertTrue([m createDirectoryAtPath:[tempPath path] withIntermediateDirectories:YES attributes:nil error:&error], [error localizedDescription]);
	
	// run 'git init'
	NSTask *task = [[[NSTask alloc] init] autorelease];
	[task setLaunchPath:@"/usr/local/bin/git"];
	[task setCurrentDirectoryPath:[tempPath path]];
	[task setArguments:[NSArray arrayWithObjects:@"init", nil]];
	[task launch];
	[task waitUntilExit];
	STAssertTrue([task terminationStatus] == 0, @"git init failed");
	
	// create a new file in working dir
	NSURL *file = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"index_dir/test.txt"]];
	[@"test content" writeToURL:file atomically:NO encoding:NSUTF8StringEncoding error:&error];
	
	// open the repo and write to the index
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:repoPath error:&error];
	STAssertNotNil(repo, [error localizedDescription]);
	BOOL success = [repo setupIndexAndReturnError:&error];
	STAssertTrue(success, [error localizedDescription]);
	success = [repo.index addFile:[file lastPathComponent] error:&error]; 
	STAssertTrue(success, [error localizedDescription]);
	success = [repo.index writeAndReturnError:&error]; 
	STAssertTrue(success, [error localizedDescription]);
	
	GTIndex *index2 = [GTIndex indexWithPath:[tempPath URLByAppendingPathComponent:@".git/index"] error:&error];
	success = [index2 refreshAndReturnError:&error];
	STAssertTrue(success, [error localizedDescription]);
	
	STAssertEqualObjects([index2 entryAtIndex:0].path, @"test.txt", nil);
#endif
}

@end
