//
//  GTReferenceTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/2/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"

@interface GTReferenceTest : GHTestCase {
	NSArray *expectedRefs;
}
@end

@implementation GTReferenceTest

- (void)setUpClass {
	
	expectedRefs = [NSArray arrayWithObjects:@"refs/heads/master", @"refs/tags/v0.9", @"refs/tags/v1.0", @"refs/heads/packed", nil];
}

- (void)testCanOpenRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByLookingUpRef:@"refs/heads/master" inRepo:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/master", ref.name, nil);
}

- (void)testCanCreateRefFromSymbolicRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"refs/heads/master" inRepo:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"refs/heads/master", ref.target, nil);
	GHAssertEqualStrings(@"tree", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref deleteAndReturnError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanCreateRefFromSha {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepo:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref deleteAndReturnError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanRenameRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepo:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref setName:@"refs/heads/new_name" error:&error];
	GHAssertTrue(success, [error localizedDescription]);
	GHAssertEqualStrings(@"refs/heads/new_name", ref.name, nil);
	
	success = [ref deleteAndReturnError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanSetTargetOnRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepo:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref setTarget:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" error:&error];

	GHAssertTrue(success, [error localizedDescription]);
	GHAssertEqualStrings(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", ref.target, nil);
	
	success = [ref deleteAndReturnError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanListAllReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [GTReference listAllReferencesInRepo:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEquals(4, (int)refs.count, nil);
	
	for(int i=0; i < refs.count; i++) {
		GHTestLog(@"%@", [refs objectAtIndex:i]);
		GHAssertEqualStrings([expectedRefs objectAtIndex:i], [refs objectAtIndex:i], nil);
	}
}

- (void)testCanListOidReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [GTReference listReferencesInRepo:repo types:GTReferenceTypesOid error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEquals(3, (int)refs.count, nil);
	
	for(int i=0; i < refs.count; i++) {
		GHAssertEqualStrings([expectedRefs objectAtIndex:i], [refs objectAtIndex:i], nil);
	}
}

- (void)testCanListSymbolicReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	// create a symbolic reference
	GTReference *ref = [GTReference referenceByCreatingRef:@"refs/heads/unit_test" fromRef:@"refs/heads/master" inRepo:repo error:&error];
	GHAssertNotNil(ref, [error localizedDescription]);
	
	@try {
		
		NSArray *refs = [GTReference listReferencesInRepo:repo types:GTReferenceTypesSymoblic error:&error];
		GHAssertNil(error, [error localizedDescription]);
		GHAssertEquals(1, (int)refs.count, nil);	
		GHAssertEqualStrings(@"refs/heads/unit_test", [refs objectAtIndex:0], nil);
	}
	@finally {
		// cleanup
		[ref deleteAndReturnError:&error];
	}
}

- (void)testCanListPackedReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [GTReference listReferencesInRepo:repo types:GTReferenceTypesPacked error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEquals(1, (int)refs.count, nil);
	
	GHAssertEqualStrings(@"refs/heads/packed", [refs objectAtIndex:0], nil);
}

@end
