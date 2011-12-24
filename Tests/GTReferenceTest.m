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
    GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByLookingUpReferencedNamed:@"refs/heads/master" inRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/master", ref.name, nil);
}

- (void)testCanOpenTagRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByLookingUpReferencedNamed:@"refs/tags/v0.9" inRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/tags/v0.9", ref.name, nil);
}

- (void)testCanCreateRefFromSymbolicRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"refs/heads/master" inRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"refs/heads/master", ref.target, nil);
	GHAssertEqualStrings(@"tree", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref deleteWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanCreateRefFromSha {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref deleteWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanRenameRef {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref setName:@"refs/heads/new_name" error:&error];
	GHAssertTrue(success, [error localizedDescription]);
	GHAssertEqualStrings(@"refs/heads/new_name", ref.name, nil);
	
	success = [ref deleteWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
	
	[pool drain];
}

- (void)testCanRenameRefAfterUsingWalker {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	(void) repo.enumerator; // walker's created lazily, so force its creation
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref setName:@"refs/heads/new_name" error:&error];
	GHAssertTrue(success, [error localizedDescription]);
	GHAssertEqualStrings(@"refs/heads/new_name", ref.name, nil);
	
	success = [ref deleteWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
	
	[pool drain];
}

- (void)testCanSetTargetOnRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(ref, nil);
	GHAssertEqualStrings(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	GHAssertEqualStrings(@"commit", ref.type, nil);
	GHAssertEqualStrings(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref setTarget:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" error:&error];

	GHAssertTrue(success, [error localizedDescription]);
	GHAssertEqualStrings(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", ref.target, nil);
	
	success = [ref deleteWithError:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

- (void)testCanListAllReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [GTReference referenceNamesInRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEquals(4, (int)refs.count, nil);
	
	for(int i=0; i < refs.count; i++) {
		GHTestLog(@"%@", [refs objectAtIndex:i]);
        GHAssertTrue([expectedRefs containsObject:[refs objectAtIndex:i]], nil);
	}
}

- (void)testCanListOidReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [GTReference referenceNamesInRepository:repo types:GTReferenceTypesOid error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEquals(3, (int)refs.count, nil);
	
	for(int i=0; i < refs.count; i++) {
		GHAssertEqualStrings([expectedRefs objectAtIndex:i], [refs objectAtIndex:i], nil);
	}
}

- (void)testCanListSymbolicReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	// create a symbolic reference
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"refs/heads/master" inRepository:repo error:&error];
	GHAssertNotNil(ref, [error localizedDescription]);
	
	@try {
		
		NSArray *refs = [GTReference referenceNamesInRepository:repo types:GTReferenceTypesSymoblic error:&error];
		GHAssertNil(error, [error localizedDescription]);
		GHAssertEquals(1, (int)refs.count, nil);	
		GHAssertEqualStrings(@"refs/heads/unit_test", [refs objectAtIndex:0], nil);
	}
	@finally {
		// cleanup
		BOOL success = [ref deleteWithError:&error];
        GHAssertTrue(success, [error localizedDescription]);
	}
}

- (void)testCanListPackedReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [GTReference referenceNamesInRepository:repo types:GTReferenceTypesPacked error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEquals(1, (int)refs.count, nil);
	
	GHAssertEqualStrings(@"refs/heads/packed", [refs objectAtIndex:0], nil);
}

@end
