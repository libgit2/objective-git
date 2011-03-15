//
//  GTBranchTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/10/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import "Contants.h"

@interface GTBranchTest : GHTestCase {
	
}
@end

@implementation GTBranchTest


- (void)testCanOpenHeadInRepo {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	GTBranch *current = [GTBranch branchFromCurrentBranchInRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(current, nil);
}

- (void)testCanListBranchesInRepo {
    
    NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
	GHAssertNil(error, [error localizedDescription]);
    
    NSArray *branches = [GTBranch listAllBranchesInRepository:repo error:&error];
    GHAssertNotNil(branches, [error localizedDescription], nil);
    GHAssertEquals(2, (int)branches.count, nil);
}

@end
