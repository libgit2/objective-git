//
//  GTRepositoryTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/21/11.
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


@interface GTRepositoryTest : GHTestCase {

	GTRepository *repo;
	GTRawObject *obj;
}
@end


@implementation GTRepositoryTest
 
- (void)setUp {
	
	NSError *error = nil;
	repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];

	obj = [[[GTRawObject alloc] initWithType:GIT_OBJ_BLOB string:@"my test data\n"] autorelease];
}

- (void)testCreateRepositoryInDirectory {
	
    NSError *error = nil;
    NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
	NSURL *newRepoURL = [NSURL URLWithString:[NSTemporaryDirectory() stringByAppendingPathComponent:@"unit_test"]];
    
    if([fm fileExistsAtPath:[newRepoURL path]]) {
        [fm removeItemAtPath:[newRepoURL path] error:&error];
        GHAssertNil(error, [error localizedDescription]);
    }
    
	GTRepository *newRepo = [GTRepository repoByCreatingRepositoryInDirectory:newRepoURL error:&error];
	
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(newRepo, nil);
	GHAssertNotNil(newRepo.fileUrl, nil);
	GHAssertNotNULL(newRepo.repo, nil);
}

- (void)testFailsToOpenNonExistentRepo {
	
	NSError *error = nil;
	GTRepository *badRepo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:@"fake/1235"] error:&error];
	
	GHAssertNil(badRepo, nil);
	GHAssertNotNil(error, nil);
	GHTestLog(@"error = %@", [error localizedDescription]);
}

- (void)testCanTellIfAnObjectExists {
	
	NSError *error = nil;
	GHAssertTrue([repo hasObject:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error], nil);
	GHAssertTrue([repo hasObject:@"1385f264afb75a56a5bec74243be9b367ba4ca08" error:&error], nil);
	GHAssertFalse([repo hasObject:@"ce08fe4884650f067bd5703b6a59a8b3b3c99a09" error:&error], nil);
	GHAssertFalse([repo hasObject:@"8496071c1c46c854b31185ea97743be6a8774479" error:&error], nil);
}

- (void)testCanReadObjectFromDb {
	
	NSError *error = nil;
	GTRawObject *rawObj = [repo read:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(rawObj, nil);
	GHAssertEqualStrings(@"tree 181037049a54a1eb5fab404658a3a250b44335d7", [[rawObj dataAsUTF8String] substringToIndex:45], nil);
	GHAssertEquals((int)[rawObj.data length], 172, nil);
	GHAssertEquals(rawObj.type, GIT_OBJ_COMMIT, nil);
}

- (void)testReadingFailsOnUnknownObjects {
	
	NSError *error = nil;
	GTRawObject *rawObj = [repo read:@"a496071c1b46c854b31185ea97743be6a8774471" error:&error];
	
	GHAssertNil(rawObj, nil);
	GHAssertNotNil(error, nil);
	GHTestLog(@"error = %@", [error localizedDescription]);
}

- (void)testCanHashData {
	
	NSError *error = nil;
	NSString *sha = [GTRepository hash:obj error:&error];
	GHAssertEqualStrings(sha, @"76b1b55ab653581d6f2c7230d34098e837197674", nil);
}

- (void)testCanWriteToDb {
	
	NSError *error = nil;
	NSString *sha = [repo write:obj error:&error];
	
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(sha, nil);
	GHAssertEqualStrings(sha, @"76b1b55ab653581d6f2c7230d34098e837197674", nil);
	GHAssertTrue([repo exists:sha error:&error], nil);
	
	rm_loose(sha);
}

- (void)testCanWalk {
	
	NSError *error = nil;
	// alloc and init to verify memory management
	GTRepository *aRepo = [[GTRepository alloc] initByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
	GHTestLog(@"%d", [aRepo retainCount]);
	NSString *sha = @"a4a7dce85cf63874e984719f4fdd239f5145052f";
	__block NSMutableArray *commits = [[[NSMutableArray alloc] init] autorelease];
	BOOL success = [aRepo walk:sha
						 error:&error
						 block:^(GTCommit *commit, BOOL *stop) {
								[commits addObject:commit];
						 }];
	GHAssertTrue(success, [error localizedDescription]);
	
	NSArray *expectedShas = [NSArray arrayWithObjects:
							 @"a4a7d",
							 @"c4780",
							 @"9fd73",
							 @"4a202",
							 @"5b5b0",
							 @"84960",
							 nil];
	for(int i=0; i < [expectedShas count]; i++) {
		GTCommit *commit = [commits objectAtIndex:i];
		GHAssertEqualStrings([commit.sha substringToIndex:5], [expectedShas objectAtIndex:i], nil);
	}
	
	GHAssertEquals(1, (int)[aRepo retainCount], nil);
	[aRepo release];
}

- (void)testCanWalkALot {
	
	NSError *error = nil;
	GTRepository *aRepo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
	NSString *sha = @"a4a7dce85cf63874e984719f4fdd239f5145052f";
	
	for(int i=0; i < 100; i++) {
		
		__block NSInteger count = 0;
		BOOL success = [aRepo walk:sha
							 error:&error
							 block:^(GTCommit *commit, BOOL *stop) {
								 count++;
							 }];
		GHAssertTrue(success, [error localizedDescription]);
		GHAssertEquals(6, (int)count, nil);
		
		[[NSGarbageCollector defaultCollector] collectExhaustively];
	}
}

- (void)testLookupHead {
	
	NSError *error = nil;
	GTReference *head = [repo headAndReturnError:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEqualStrings(head.target, @"36060c58702ed4c2a40832c51758d5344201d89a", nil);
	GHAssertEqualStrings(head.type, @"commit", nil);
}

- (void)testWalkCommitAndThenWalkAgain {
	NSError *error = nil;
	// alloc and init to verify memory management
	GTRepository *aRepo = [[GTRepository alloc] initByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
	GHTestLog(@"%d", [aRepo retainCount]);
	NSString *sha = @"a4a7dce85cf63874e984719f4fdd239f5145052f";
	__block NSMutableArray *commits = [[[NSMutableArray alloc] init] autorelease];
	BOOL success = [aRepo walk:sha
						 error:&error
						 block:^(GTCommit *commit, BOOL *stop) {
							 [commits addObject:commit];
						 }];
	GHAssertTrue(success, [error localizedDescription]);
	
	NSArray *expectedShas = [NSArray arrayWithObjects:
							 @"a4a7d",
							 @"c4780",
							 @"9fd73",
							 @"4a202",
							 @"5b5b0",
							 @"84960",
							 nil];
	for(int i=0; i < [expectedShas count]; i++) {
		GTCommit *commit = [commits objectAtIndex:i];
		GHAssertEqualStrings([commit.sha substringToIndex:5], [expectedShas objectAtIndex:i], nil);
	}
	
	NSString *tsha = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";
	GTObject *aObj = [aRepo lookupBySha:tsha error:&error];
	
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(aObj, nil);
	GHAssertTrue([aObj isKindOfClass:[GTTree class]], nil);
	GTTree *tree = (GTTree *)aObj;
	
	GTCommit *commit = [[[GTCommit alloc] initInRepo:repo error:&error] autorelease];
	GTSignature *person = [[[GTSignature alloc] 
							initWithName:@"Tim" 
							email:@"tclem@github.com" 
							time:[NSDate date]] autorelease];
	
	commit.message = @"new message";
	commit.author = person;
	commit.commiter = person;
	commit.tree = tree;
	NSString *newSha = [commit writeAndReturnError:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(newSha, nil);
	GHTestLog(@"wrote sha %@", newSha);
	
	__block GTCommit *firstCommit = nil;
	success = [aRepo walk:nil
				  sorting:GTWalkerOptionsTopologicalSort
					error:&error
					block:^(GTCommit *commit, BOOL *stop) {
						firstCommit = commit;
						*stop = YES;
					}];
	GHAssertTrue(success, [error localizedDescription]);
	
	GHAssertEqualStrings(firstCommit.sha, newSha, @"The first commit from the walker isn't the commit we just made.");
	
	rm_loose(newSha);
	
	GHAssertEquals(1, (int)[aRepo retainCount], nil);
	[aRepo release];
}

@end
