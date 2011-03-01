//
//  GTObjectTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/24/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"

@interface GTObjectTest : GHTestCase {

	GTRepository *repo;
}
@end

@implementation GTObjectTest

- (void)setUpClass {

	NSError *error = nil;
	repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
}

- (void)tearDownClass {
	
	// make sure our memory mgt is working
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}

- (void)testCanLookupEmptyStringFails {
	
	NSError *error = nil;
	GTObject *obj = [repo lookup:@"" error:&error];
	
	GHAssertNotNil(error, nil);
	GHAssertNil(obj, nil);
	GHTestLog(@"Error = %@", [error localizedDescription]);
}

- (void)testCanLookupBadObjectFails {
	
	NSError *error = nil;
	GTObject *obj = [repo lookup:@"a496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	GHAssertNotNil(error, nil);
	GHAssertNil(obj, nil);
	GHTestLog(@"Error = %@", [error localizedDescription]);
}

- (void)testCanLookupAnObject {
	
	NSError *error = nil;
	GTObject *obj = [repo lookup:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	GHAssertNil(error, nil);
	GHAssertNotNil(obj, nil);
	GHAssertEqualStrings(obj.type, @"commit", nil);
	GHAssertEqualStrings(obj.sha, @"8496071c1b46c854b31185ea97743be6a8774479", nil);
}

- (void)testTwoObjectsAreTheSame {
	
	NSError *error = nil;
	GTObject *obj1 = [repo lookup:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	GTObject *obj2 = [repo lookup:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	GHAssertNotNil(obj1, nil);
	GHAssertNotNil(obj2, nil);
	GHAssertTrue([obj1 isEqual:obj2], nil);
}

- (void)testCanReadRawDataFromObject {

	NSError *error = nil;
	GTObject *obj = [repo lookup:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];

	GHAssertNotNil(obj, nil);
	
	GTRawObject *rawObj = [obj readRawAndReturnError:&error];
	GHAssertNotNil(rawObj, nil);
	GHAssertNil(error, nil);
	GHTestLog(@"rawObj len = %d", [rawObj.data length]);
}

@end
