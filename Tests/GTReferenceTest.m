//
//  GTReferenceTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/2/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"

@interface GTReferenceTest : GHTestCase {
	
}
@end

@implementation GTReferenceTest

-(void)testCanOpenRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, nil);
	GTReference *ref = [GTReference referenceByLookingUpRef:@"refs/heads/master" inRepo:repo error:&error];
	GHAssertNil(error, nil);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/master", ref.name, nil);
}

-(void)testCanCreateRefFromSymbolicRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, nil);
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"refs/heads/master" inRepo:repo error:&error];
	GHAssertNil(error, nil);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"refs/heads/master", ref.target, nil);
	GHAssertEqualStrings(@"tree", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	[ref deleteAndReturnError:&error];
	GHAssertNil(error, nil);
}

@end
