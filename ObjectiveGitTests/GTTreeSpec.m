//
//  GTTreeSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 5/10/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTTree.h"
#import "GTTreeEntry.h"

static NSString * const testTreeSHA = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";

SpecBegin(GTTree)

__block GTTree *tree;

beforeEach(^{
	GTRepository *repo = [self fixtureRepositoryNamed:@"testrepo.git"];
	expect(repo).notTo.beNil();

	tree = (GTTree *)[repo lookupObjectBySha:testTreeSHA error:NULL];
	expect(tree).notTo.beNil();
});

it(@"should be able to read tree properties", ^{
	expect(tree.sha).to.equal(testTreeSHA);
	expect(tree.entryCount).to.equal(3);
});

it(@"should be able to read tree entry properties", ^{
	GTTreeEntry *entry = [tree entryAtIndex:0];
	expect(entry).notTo.beNil();
	expect(entry.name).to.equal(@"README");
	expect(entry.sha).to.equal(@"1385f264afb75a56a5bec74243be9b367ba4ca08");
});

SpecEnd
