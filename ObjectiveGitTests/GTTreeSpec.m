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

it(@"should be possible to fast enumerate the entries", ^{
	NSUInteger index = 0;
	NSUInteger entryCount = tree.entryCount;
	for (GTTreeEntry *entry in tree) {
		expect(entry).to.beKindOf(GTTreeEntry.class);
		if (index == 0) {
			expect(entry.name).to.equal(@"README");
			expect(entry.sha).to.equal(@"1385f264afb75a56a5bec74243be9b367ba4ca08");
		}
		index++;
	}
	expect(entryCount).to.equal(index);
});

it(@"should be possible to fast enumerate the entries in a large tree", ^{
	
	NSError *error = nil;
	GTTreeBuilder *builder = nil;
	
	builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
	expect(builder).notTo.beNil();
	expect(error).to.beNil();	
	
	GTRepository *repo = [self fixtureRepositoryNamed:@"testrepo.git"];
	expect(repo).notTo.beNil();
	
	NSUInteger entryCount = 100;
	for (NSUInteger i=0; i<entryCount; i++) {
		NSString *string = [NSString stringWithFormat:@"%lu.txt", (unsigned long)i];
		GTBlob *blob = [GTBlob blobWithString:string inRepository:repo error:&error];
		[builder addEntryWithSHA:blob.sha filename:string filemode:GTFileModeTree error:&error];
	}
		
	GTTree *writtenTree = [builder writeTreeToRepository:repo error:&error];
	expect(writtenTree).notTo.beNil();
	expect(error).to.beNil();
	
	NSUInteger index = 0;
	for (GTTreeEntry *entry in writtenTree)
		index++;		
	expect(entryCount).to.equal(index);
});

SpecEnd
