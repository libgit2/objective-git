//
//  GTIndexSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 5/10/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTIndex.h"

SpecBegin(GTIndex)

__block GTIndex *index;

beforeEach(^{
	NSURL *indexURL = [[self fixtureRepositoryNamed:@"testrepo.git"].gitDirectoryURL URLByAppendingPathComponent:@"index"];
	index = [[GTIndex alloc] initWithFileURL:indexURL error:NULL];
	expect(index).notTo.beNil();

	BOOL success = [index refresh:NULL];
	expect(success).to.beTruthy();
});

it(@"can count the entries", ^{
	expect(index.entryCount).to.equal(2);
});

it(@"can clear all entries", ^{
	[index clear];
	expect(index.entryCount).to.equal(0);
});

it(@"can read entry properties", ^{
	GTIndexEntry *entry = [index entryAtIndex:0];
	expect(entry).notTo.beNil();
	expect(entry.path).to.equal(@"README");
	expect(entry.staged).to.beFalsy();
});

it(@"can write to the repository and return a tree", ^{
	GTRepository *repository = [self fixtureRepositoryNamed:@"testrepo.git"];
	GTIndex *index = [repository indexWithError:NULL];
	GTTree *tree = [index writeTree:NULL];
	expect(tree).notTo.beNil();
	expect(tree.entryCount).to.equal(2);
	expect(tree.repository).to.equal(repository);
});

SpecEnd
