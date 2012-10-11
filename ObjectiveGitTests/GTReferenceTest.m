//
//  GTReferenceTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/2/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"


@interface GTReferenceTest : SenTestCase {
	NSArray *expectedRefs;
}
@end

@implementation GTReferenceTest

- (void)setUp {
	
	expectedRefs = [NSArray arrayWithObjects:@"refs/heads/master", @"refs/tags/v0.9", @"refs/tags/v1.0", @"refs/heads/packed", nil];
}

- (void)testCanOpenRef {
	
	NSError *error = nil;
    GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByLookingUpReferencedNamed:@"refs/heads/master" inRepository:repo error:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(ref, nil);
	
	STAssertEqualObjects(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	STAssertEqualObjects(@"commit", ref.type, nil);
	STAssertEqualObjects(@"refs/heads/master", ref.name, nil);
}

- (void)testCanOpenTagRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByLookingUpReferencedNamed:@"refs/tags/v0.9" inRepository:repo error:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(ref, nil);
	
	STAssertEqualObjects(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", ref.target, nil);
	STAssertEqualObjects(@"commit", ref.type, nil);
	STAssertEqualObjects(@"refs/tags/v0.9", ref.name, nil);
}

- (void)testCanCreateRefFromSymbolicRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"refs/heads/master" inRepository:repo error:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(ref, nil);
	
	STAssertEqualObjects(@"refs/heads/master", ref.target, nil);
	STAssertEqualObjects(@"tree", ref.type, nil);
	STAssertEqualObjects(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref deleteWithError:&error];
	STAssertTrue(success, [error localizedDescription]);
}

- (void)testCanCreateRefFromSha {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepository:repo error:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(ref, nil);
	
	STAssertEqualObjects(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	STAssertEqualObjects(@"commit", ref.type, nil);
	STAssertEqualObjects(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref deleteWithError:&error];
	STAssertTrue(success, [error localizedDescription]);
}

- (void)testCanRenameRef {
	@autoreleasepool {
	
		NSError *error = nil;
		GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
		STAssertNil(error, [error localizedDescription]);
		GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepository:repo error:&error];
		STAssertNil(error, [error localizedDescription]);
		STAssertNotNil(ref, nil);
		STAssertEqualObjects(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
		STAssertEqualObjects(@"commit", ref.type, nil);
		STAssertEqualObjects(@"refs/heads/unit_test", ref.name, nil);
		
		BOOL success = [ref setName:@"refs/heads/new_name" error:&error];
		STAssertTrue(success, [error localizedDescription]);
		STAssertEqualObjects(@"refs/heads/new_name", ref.name, nil);
		
		success = [ref deleteWithError:&error];
		STAssertTrue(success, [error localizedDescription]);
	
	}
}

- (void)testCanRenameRefAfterUsingWalker {
	@autoreleasepool {
	
		NSError *error = nil;
		GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
		STAssertNil(error, [error localizedDescription]);
		(void) repo.enumerator; // walker's created lazily, so force its creation
		GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepository:repo error:&error];
		STAssertNil(error, [error localizedDescription]);
		STAssertNotNil(ref, nil);
		STAssertEqualObjects(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
		STAssertEqualObjects(@"commit", ref.type, nil);
		STAssertEqualObjects(@"refs/heads/unit_test", ref.name, nil);
		
		BOOL success = [ref setName:@"refs/heads/new_name" error:&error];
		STAssertTrue(success, [error localizedDescription]);
		STAssertEqualObjects(@"refs/heads/new_name", ref.name, nil);
		
		success = [ref deleteWithError:&error];
		STAssertTrue(success, [error localizedDescription]);
	
	}
}

- (void)testCanSetTargetOnRef {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"36060c58702ed4c2a40832c51758d5344201d89a" inRepository:repo error:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(ref, nil);
	STAssertEqualObjects(@"36060c58702ed4c2a40832c51758d5344201d89a", ref.target, nil);
	STAssertEqualObjects(@"commit", ref.type, nil);
	STAssertEqualObjects(@"refs/heads/unit_test", ref.name, nil);
	
	BOOL success = [ref setTarget:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" error:&error];

	STAssertTrue(success, [error localizedDescription]);
	STAssertEqualObjects(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", ref.target, nil);
	
	success = [ref deleteWithError:&error];
	STAssertTrue(success, [error localizedDescription]);
}

- (void)testCanListAllReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [repo referenceNamesWithError:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertEquals(4, (int)refs.count, nil);
	
	for(int i=0; i < refs.count; i++) {
		NSLog(@"%@", [refs objectAtIndex:i]);
        STAssertTrue([expectedRefs containsObject:[refs objectAtIndex:i]], nil);
	}
}

- (void)testCanListOidReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [repo referenceNamesWithTypes:GTReferenceTypesOid error:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertEquals(3, (int)refs.count, nil);
	
	for(int i=0; i < refs.count; i++) {
		STAssertEqualObjects([expectedRefs objectAtIndex:i], [refs objectAtIndex:i], nil);
	}
}

- (void)testCanListSymbolicReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	
	// create a symbolic reference
	GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/unit_test" fromReferenceTarget:@"refs/heads/master" inRepository:repo error:&error];
	STAssertNotNil(ref, [error localizedDescription]);
	
	@try {
		
		NSArray *refs = [repo referenceNamesWithTypes:GTReferenceTypesSymbolic error:&error];
		STAssertNil(error, [error localizedDescription]);
		STAssertEquals(1, (int)refs.count, nil);	
		STAssertEqualObjects(@"refs/heads/unit_test", [refs objectAtIndex:0], nil);
	}
	@finally {
		// cleanup
		BOOL success = [ref deleteWithError:&error];
        STAssertTrue(success, [error localizedDescription]);
	}
}

- (void)testCanListPackedReferences {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	
	NSArray *refs = [repo referenceNamesWithTypes:GTReferenceTypesPacked error:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertEquals(1, (int)refs.count, nil);
	
	STAssertEqualObjects(@"refs/heads/packed", [refs objectAtIndex:0], nil);
}

@end
