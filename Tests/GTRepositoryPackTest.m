//
//  GTRepositoryPackTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"

@interface GTRepositoryPackTest : GHTestCase {
	
	GTRepository *repo;
}
@end

@implementation GTRepositoryPackTest

- (void)setUp {
	
	NSError *error = nil;
	repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
}

- (void)tearDownClass {
	
	// make sure our memory mgt is working
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}

- (void)testCanTellIfPackedObjectExists {
	
	GHAssertTrue([repo exists:@"41bc8c69075bbdb46c5c6f0566cc8cc5b46e8bd9"], nil);
	GHAssertTrue([repo exists:@"f82a8eb4cb20e88d1030fd10d89286215a715396"], nil);
}

- (void)testCanReadAPackedObjectFromDb {

	NSError *error = nil;
	GTRawObject *obj = [repo read:@"41bc8c69075bbdb46c5c6f0566cc8cc5b46e8bd9" error:&error];
	
	GHAssertEquals(230, (int)[obj.data length], nil);
	GHAssertEquals(GIT_OBJ_COMMIT, obj.type, nil);
}

@end
