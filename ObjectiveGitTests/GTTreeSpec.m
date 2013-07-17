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

	tree = (GTTree *)[repo lookupObjectBySHA:testTreeSHA error:NULL];
	expect(tree).notTo.beNil();
});

it(@"should be able to read tree properties", ^{
	expect(tree.SHA).to.equal(testTreeSHA);
	expect(tree.entryCount).to.equal(3);
});

it(@"should be able to read tree entry properties", ^{
	GTTreeEntry *entry = [tree entryAtIndex:0];
	expect(entry).notTo.beNil();
	expect(entry.name).to.equal(@"README");
	expect(entry.SHA).to.equal(@"1385f264afb75a56a5bec74243be9b367ba4ca08");
});

it(@"should give quick access to its contents", ^{
	NSArray *treeContents = tree.contents;
	expect(treeContents).notTo.beNil();
	expect(treeContents.count).to.equal(3);
	GTTreeEntry *readme = [tree entryWithName:@"README"];
	GTTreeEntry *newTxt = [tree entryWithName:@"new.txt"];
	GTTreeEntry *subdir = [tree entryWithName:@"subdir"];
	expect(readme).notTo.beNil();
	expect(newTxt).notTo.beNil();
	expect(subdir).notTo.beNil();
	expect(treeContents).to.contain(readme);
	expect(treeContents).to.contain(newTxt);
	expect(treeContents).to.contain(subdir);
});

it(@"should return nil for non-existent entries", ^{
	expect([tree entryAtIndex:99]).to.beNil();
	expect([tree entryWithName:@"_does not exist"]).to.beNil();
});

SpecEnd
