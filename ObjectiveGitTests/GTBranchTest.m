//
//  GTBranchTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/10/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

@interface GTBranchTest : GTTestCase {

        GTRepository *repo;
}
@end

@implementation GTBranchTest

- (void)setUp {
	repo = self.bareFixtureRepository;
}

- (void)testRetainOfBranchCreatedWithRef {

	// Hard to test the autoreleasepool, so manually alloc/init instead.
	// This allows us to release the object and test that the branch
	// is retaining properly.
    NSError *error = nil;
    GTReference *head = [[GTReference alloc] initByLookingUpReferenceNamed:@"HEAD" inRepository:repo error:&error];
	STAssertNotNil(head, [error localizedDescription]);
	GTBranch *current = [GTBranch branchWithReference:head repository:repo];
	STAssertNotNil(current, [error localizedDescription]);


    STAssertNotNil(current.reference, nil);
}

@end
