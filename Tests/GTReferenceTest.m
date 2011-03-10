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

-(void)testCanCreateRefFromSha {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, nil);
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepo:repo error:&error];
	GHAssertNil(error, nil);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	[ref deleteAndReturnError:&error];
	GHAssertNil(error, [error localizedDescription]);
}

-(void)testCanRenameRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, nil);
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepo:repo error:&error];
	GHAssertNil(error, nil);
	GHAssertNotNil(ref, nil);
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	[ref setName:@"refs/heads/new_name" error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEqualStrings(@"refs/heads/new_name", ref.name, nil);
	
	[ref deleteAndReturnError:&error];
	GHAssertNil(error, [error localizedDescription]);
}

-(void)testCanSetTargetOnRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepo:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	[ref setTarget:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" error:&error];
	
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEqualStrings(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", ref.target, nil);
	
	[ref deleteAndReturnError:&error];
	GHAssertNil(error, [error localizedDescription]);
}

@end
