//
//  GTRepositoryTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/21/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"

static NSString *NewRepoPath = @"file://localhost/Users/tclem/github/local/unit_test";

@interface GTRepositoryTest : GHTestCase {

	GTRepository *repo;
	GTRawObject *obj;
}
@end


@implementation GTRepositoryTest
 
- (void)setUpClass {
	
	NSError *error = nil;
	repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];

	obj = [[GTRawObject alloc] initWithType:GIT_OBJ_BLOB string:@"my test data\n"];
	
	[[NSFileManager defaultManager] removeItemAtPath:NewRepoPath error:&error];
}

- (void)tearDownClass {
	
	// make sure our memory mgt is working
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}

- (void)testCreateRepositoryInDirectory {
	
	NSError *error = nil;
	GTRepository *newRepo = [GTRepository repoByCreatingRepositoryInDirectory:[NSURL URLWithString:NewRepoPath] error:&error];
	
	GHAssertNotNil(newRepo, nil);
	GHAssertNil(error, nil);
	GHAssertNotNil(newRepo.fileUrl, nil);
	GHAssertNotNULL(newRepo.repo, nil);
}

/*
- (void)testFailsToOpenNonExistentRepo {
	
	NSError *error = nil;
	GTRepository *badRepo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:@"fake/1235"] error:&error];
	
	GHAssertNil(badRepo, nil);
	GHAssertNotNil(error, nil);
	GHTestLog(@"error = %@", [error localizedDescription]);
}*/

- (void)testCanTellIfAnObjectExists {
	
	GHAssertTrue([repo hasObject:@"8496071c1b46c854b31185ea97743be6a8774479"], nil);
	GHAssertTrue([repo hasObject:@"1385f264afb75a56a5bec74243be9b367ba4ca08"], nil);
	GHAssertFalse([repo hasObject:@"ce08fe4884650f067bd5703b6a59a8b3b3c99a09"], nil);
	GHAssertFalse([repo hasObject:@"8496071c1c46c854b31185ea97743be6a8774479"], nil);
}

- (void)testCanReadObjectFromDb {
	
	NSError *error = nil;
	GTRawObject *rawObj = [repo read:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	GHAssertNotNil(rawObj, nil);
	GHAssertNil(error, nil);
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
	
	GHAssertNil(error, nil);
	GHAssertNotNil(sha, nil);
	GHAssertEqualStrings(sha, @"76b1b55ab653581d6f2c7230d34098e837197674", nil);
	GHAssertTrue([repo exists:sha], nil);
	
	rm_loose(sha);
}

- (void)testCanWalk {
	
	NSError *error = nil;
	GTRepository *aRepo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	NSString *sha = @"a4a7dce85cf63874e984719f4fdd239f5145052f";
	__block NSMutableArray *commits = [[NSMutableArray alloc] init];
	[aRepo walk:sha 
		  error:&error
		  block:^(GTCommit *commit){
			 [commits addObject:commit];
		 }];
	GHAssertNil(error, nil);
	
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
}

@end
