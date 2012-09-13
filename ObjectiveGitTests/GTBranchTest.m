//
//  GTBranchTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/10/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import "Contants.h"

@interface GTBranchTest : SenTestCase {

        GTRepository *repo;
}
@end

@implementation GTBranchTest

- (void)setUp {
	
	NSError *error = nil;
    repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
}

- (void)testCanOpenHeadInRepo {
	
    NSError *error = nil;
	GTBranch *current = [repo currentBranchWithError:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(current, nil);
}

- (void)testCanListLocalBranchesInRepo {
	
    NSError *error = nil;
	NSArray *branches = [repo localBranchesWithError:&error];
	STAssertNotNil(branches, [error localizedDescription], nil);
	STAssertEquals(2, (int)branches.count, nil);
}

- (void)testCanListRemoteBranchesInRepo {
	
    NSError *error = nil;
	NSArray *branches = [repo remoteBranchesWithError:&error];
	STAssertNotNil(branches, [error localizedDescription], nil);
	STAssertEquals(0, (int)branches.count, nil);
}

- (void)testCanCountCommitsInBranch {
	
    NSError *error = nil;
	GTReference *head = [repo headReferenceWithError:&error];
	STAssertNotNil(head, [error localizedDescription]);
	GTBranch *master = [GTBranch branchWithReference:head repository:repo];
	STAssertNotNil(master, [error localizedDescription]);
	
	NSUInteger n = [master numberOfCommitsWithError:&error];
	STAssertEquals((NSUInteger)3, n, nil);
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

/*
- (void)testCanRenameBranch {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
	STAssertNil(error, [error localizedDescription]);
	
	NSArray *branches = [GTBranch listAllLocalBranchesInRepository:repo error:&error];
	STAssertNotNil(branches, [error localizedDescription], nil);
	STAssertEquals(2, (int)branches.count, nil);
	
	NSString *newBranchName = [NSString stringWithFormat:@"%@%@", [GTBranch localNamePrefix], @"this_is_the_renamed_branch"];
	GTBranch *firstBranch = [branches objectAtIndex:0];
	NSString *originalBranchName = firstBranch.name;
	BOOL success = [firstBranch.reference setName:newBranchName error:&error];
	STAssertTrue(success, [error localizedDescription]);
	STAssertEqualObjects(firstBranch.name, newBranchName, nil);
	
	success = [firstBranch.reference setName:originalBranchName error:&error];
	STAssertTrue(success, [error localizedDescription]);
	STAssertEqualObjects(firstBranch.name, originalBranchName, nil);
}
 */

@end
