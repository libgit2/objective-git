//
//  GTTreeTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/25/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"

@interface GTTreeTest : GHTestCase {
	
	GTRepository *repo;
	NSString *sha;
	GTTree *tree;
}
@end

@implementation GTTreeTest

- (void)setUp {
	
	NSError *error = nil;
	repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	sha = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";
	tree = (GTTree *)[repo lookup:sha error:&error];
}

- (void)tearDownClass {
	
	// make sure our memory mgt is working
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}

- (void)testCanReadTreeData {
	
	GHAssertEqualStrings(sha, tree.sha, nil);
	GHAssertEqualStrings(@"tree", tree.type, nil);
	GHAssertTrue([tree entryCount] == 3, nil);
	GHAssertEqualStrings(@"1385f264afb75a56a5bec74243be9b367ba4ca08", [tree entryAtIndex:0].sha, nil);
	GHAssertEqualStrings(@"fa49b077972391ad58037050f2a75f74e3671e92", [tree entryAtIndex:1].sha, nil);
}

- (void)testCanReadTreeEntryData {
	
	NSError	*error = nil;
	GTTreeEntry *bent = [tree entryAtIndex:0];
	GTTreeEntry *tent = [tree entryAtIndex:2];
	
	GTObject *bentObj = [bent toObjectAndReturnError:&error];
	GHAssertNil(error, nil);
	GHAssertEqualStrings(@"README", bent.name, nil);
	GHAssertEqualStrings(bentObj.sha, bent.sha, nil);
	
	GTObject *tentObj = [tent toObjectAndReturnError:&error];
	GHAssertNil(error, nil);
	GHAssertEqualStrings(@"subdir", tent.name, nil);
	GHAssertEqualStrings(@"619f9935957e010c419cb9d15621916ddfcc0b96", tentObj.sha, nil);
	GHAssertEqualStrings(@"tree", tentObj.type, nil);
}

@end
