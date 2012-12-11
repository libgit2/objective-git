//
//  GTDiffTest.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 04/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "Contants.h"

#import "GTDiff.h"

@interface GTDiffTest : SenTestCase

@property (nonatomic, strong) GTRepository *repository;

@end

@implementation GTDiffTest

- (GTCommit *)findCommitWithSHA:(NSString *)sha {
	return (GTCommit *)[self.repository lookupObjectBySha:sha objectType:GTObjectTypeCommit error:NULL];
}

- (void)setUp {
	self.repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:NULL];
	STAssertNotNil(self.repository, @"Failed to initialise repository.");
}

- (void)testDiffingTrees {
	GTCommit *firstCommit = [self findCommitWithSHA:@"5b5b025afb0b4c913b4c338a42934a3863bf3644"];
	GTCommit *secondCommit = [self findCommitWithSHA:@"36060c58702ed4c2a40832c51758d5344201d89a"];
	STAssertNotNil(firstCommit, @"Could not find first commit to diff against");
	STAssertNotNil(secondCommit, @"Could not find second commit to diff against");
	
	GTTree *firstTree = firstCommit.tree;
	GTTree *secondTree = secondCommit.tree;
	GTDiff *diff = [GTDiff diffOldTree:firstTree withNewTree:secondTree options:nil];
	STAssertNotNil(diff, @"Unable to create a diff object with 2 trees.");
}

@end
