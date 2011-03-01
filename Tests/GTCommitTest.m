//
//  GTCommitTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"


@interface GTCommitTest : GHTestCase {

	GTRepository *repo;
}
@end

@implementation GTCommitTest


- (void)setUpClass {

	NSError *error = nil;
	repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
}

- (void)tearDownClass {
	
	// make sure our memory mgt is working
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}

- (void)testCanReadCommitData {
	
	NSString *sha = @"8496071c1b46c854b31185ea97743be6a8774479";
	NSError *error = nil;
	GTObject *obj = [repo lookup:sha error:&error];
	
	GHAssertNil(error, nil);
	GHAssertNotNil(obj, nil);
	GHAssertTrue([obj isKindOfClass:[GTCommit class]], nil);
	GHAssertEqualStrings(obj.type, @"commit", nil);
	GHAssertEqualStrings(obj.sha, sha, nil);
	
	GTCommit *commit = (GTCommit *)obj;
	GHAssertEqualStrings(commit.message, @"testing\n", nil);
	GHAssertEqualStrings(commit.messageShort, @"testing", nil);
	GHAssertEquals((int)[commit.time timeIntervalSince1970], 1273360386, nil); 
	
	GTSignature *author = commit.author;
	GHAssertEqualStrings(author.name, @"Scott Chacon", nil);
	GHAssertEqualStrings(author.email, @"schacon@gmail.com", nil);
	GHAssertEquals((int)[author.time timeIntervalSince1970], 1273360386, nil);
	
	GTSignature *commiter = commit.commiter;
	GHAssertEqualStrings(commiter.name, @"Scott Chacon", nil);
	GHAssertEqualStrings(commiter.email, @"schacon@gmail.com", nil);
	GHAssertEquals((int)[commiter.time timeIntervalSince1970], 1273360386, nil);
	
	GHAssertEqualStrings(commit.tree.sha, @"181037049a54a1eb5fab404658a3a250b44335d7", nil);
	GHAssertTrue([commit.parents count] == 0, nil);
}

- (void)testCanHaveMultipleParents {
	
	NSString *sha = @"a4a7dce85cf63874e984719f4fdd239f5145052f";
	NSError *error = nil;
	GTObject *obj = [repo lookup:sha error:&error];
	
	GHAssertNil(error, nil);
	GHAssertNotNil(obj, nil);
	
	GTCommit *commit = (GTCommit *)obj;
	GHAssertTrue([commit.parents count] == 2, nil);
}

- (void)testCanWriteCommitData {
	
	NSError *error = nil;
	NSString *sha = @"8496071c1b46c854b31185ea97743be6a8774479";
	GTCommit *obj = (GTCommit *)[repo lookup:sha error:&error];
	GHAssertNotNil(obj, nil);
	GHAssertNil(error, nil);
	
	obj.message = @"new message";
	NSString *newSha = [obj writeAndReturnError:&error];
	
	GHAssertNotNil(newSha, nil);
	GHAssertNil(error, nil);
	rm_loose(newSha);
}

- (void)testCanWriteNewCommitData {
	
	NSString *tsha = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";
	NSError *error = nil;
	GTObject *obj = [repo lookup:tsha error:&error];
	
	GHAssertNil(error, nil);
	GHAssertNotNil(obj, nil);
	GHAssertTrue([obj isKindOfClass:[GTTree class]], nil);
	GTTree *tree = (GTTree *)obj;

	GTCommit *commit = [[GTCommit alloc] initInRepo:repo error:&error];
	GTSignature *person = [[GTSignature alloc] 
						   initWithName:@"Tim" 
						   email:@"tclem@github.com" 
						   time:[NSDate date]];
	
	commit.message = @"new message";
	commit.author = person;
	commit.commiter = person;
	commit.tree = tree;
	NSString *newSha = [commit writeAndReturnError:&error];
	GHAssertNil(error, nil);
	GHAssertNotNil(newSha, nil);
	GHTestLog(@"wrote sha %@", newSha);
	
	rm_loose(newSha);
}

@end
