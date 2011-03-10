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
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:@"file://localhost/Users/tclem/github/local/libgit2"] error:&error];
	GHAssertNil(error, [error localizedDescription]);
	
	GTBranch *current = [GTBranch branchFromCurrentBranchInRepository:repo error:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(current, nil);
}

@end
