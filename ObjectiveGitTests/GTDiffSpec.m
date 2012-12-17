//
//  GTDiffSpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 17/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "Contants.h"

SpecBegin(GTDiff)

__block GTRepository *repository = nil;
__block GTCommit *firstCommit = nil;
__block GTCommit *secondCommit = nil;

describe(@"GTDiff initialisation", ^{
	beforeEach(^{
		repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:NULL];
		expect(repository).toNot.beNil();
		
		firstCommit = (GTCommit *)[repository lookupObjectBySha:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" objectType:GTObjectTypeCommit error:NULL];
		expect(firstCommit).toNot.beNil();
		
		secondCommit = (GTCommit *)[repository lookupObjectBySha:@"36060c58702ed4c2a40832c51758d5344201d89a" objectType:GTObjectTypeCommit error:NULL];
		expect(secondCommit).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff from 2 trees", ^{
		expect([GTDiff diffOldTree:firstCommit.tree withNewTree:secondCommit.tree options:nil]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against the index with a tree", ^{
		expect([GTDiff diffIndexToTree:secondCommit.tree options:nil]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against a working directory and a tree", ^{
		expect([GTDiff diffWorkingDirectoryToTree:firstCommit.tree options:nil]).toNot.beNil();
	});
	
	it(@"should be able to initialse a diff against an index from a repo's working directory", ^{
		expect([GTDiff diffWorkingDirectoryToIndexInRepository:repository options:nil]).toNot.beNil();
	});
});

SpecEnd
