//
//  GTTreeSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 5/10/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

static NSString * const testTreeSHA = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";

QuickSpecBegin(GTTreeSpec)

__block GTTree *tree;

beforeEach(^{
	GTRepository *repo = self.bareFixtureRepository;
	expect(repo).notTo(beNil());

	tree = (GTTree *)[repo lookUpObjectBySHA:testTreeSHA error:NULL];
	expect(tree).notTo(beNil());
});

it(@"should be able to read tree properties", ^{
	expect(tree.SHA).to(equal(testTreeSHA));
	expect(@(tree.entryCount)).to(equal(@3));
});

it(@"should be able to read tree entry properties", ^{
	GTTreeEntry *entry = [tree entryAtIndex:0];
	expect(entry).notTo(beNil());
	expect(entry.name).to(equal(@"README"));
	expect(entry.SHA).to(equal(@"1385f264afb75a56a5bec74243be9b367ba4ca08"));
});

it(@"should give quick access to its entries", ^{
	NSArray *treeEntries = tree.entries;
	expect(treeEntries).notTo(beNil());
	expect(@(treeEntries.count)).to(equal(@3));
	GTTreeEntry *readme = [tree entryWithName:@"README"];
	GTTreeEntry *newTxt = [tree entryWithName:@"new.txt"];
	GTTreeEntry *subdir = [tree entryWithName:@"subdir"];
	expect(readme).notTo(beNil());
	expect(newTxt).notTo(beNil());
	expect(subdir).notTo(beNil());
	expect(treeEntries).to(contain(readme));
	expect(treeEntries).to(contain(newTxt));
	expect(treeEntries).to(contain(subdir));
});

describe(@"tree enumeration", ^{
	it(@"should stop when instructed", ^{
		NSMutableArray *mutableArray = [NSMutableArray array];
		BOOL success = [tree enumerateEntriesWithOptions:GTTreeEnumerationOptionPre error:nil block:^(GTTreeEntry *entry, NSString *root, BOOL *stop) {
			if ([entry.name isEqualToString:@"README"]) {
				*stop = YES;
			}
			[mutableArray addObject:entry];
			return YES;
		}];

		expect(@(success)).to(beTruthy());
		expect(@(mutableArray.count)).to(equal(@1));
	});

	it(@"should be able to enumerate descendants", ^{
		NSMutableArray *entriesInASubtree = [NSMutableArray array];
		BOOL success = [tree enumerateEntriesWithOptions:GTTreeEnumerationOptionPre error:nil block:^(GTTreeEntry *entry, NSString *root, BOOL *stop) {
			if (![root isEqualToString:@""]) {
				[entriesInASubtree addObject:entry];
			}
			return YES;
		}];

		expect(@(success)).to(beTruthy());
		expect(@(entriesInASubtree.count)).to(equal(@5));
	});

	it(@"should be able to enumerate in post-order", ^{
		NSMutableArray *entries = [NSMutableArray array];
		BOOL success = [tree enumerateEntriesWithOptions:GTTreeEnumerationOptionPost error:nil block:^(GTTreeEntry *entry, NSString *root, BOOL *stop) {
			[entries addObject:entry];
			// Because we are enumerating in post-order the return statement has no impact.
			return NO;
		}];

		expect(@(success)).to(beTruthy());
		expect(@(entries.count)).to(equal(@8));
	});
});

it(@"should return nil for non-existent entries", ^{
	expect([tree entryAtIndex:99]).to(beNil());
	expect([tree entryWithName:@"_does not exist"]).to(beNil());
});

describe(@"fetching entries from paths", ^{
	it(@"should be able to fetch existing paths",^{
		NSError *error = nil;
		GTTreeEntry *entry;
		
		entry = [tree entryWithPath:@"README" error:&error];
		expect(error).to(beNil());
		expect(entry).notTo(beNil());
		
		entry = [tree entryWithPath:@"subdir/README" error:&error];
		expect(error).to(beNil());
		expect(entry).notTo(beNil());
	});
	
	it(@"should return nil and fill error for non-existent paths",^{
		NSError *error = nil;
		GTTreeEntry *entry;
		
		entry = [tree entryWithPath:@"does/not/exist" error:&error];
		expect(error).notTo(beNil());
		expect(entry).to(beNil());
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
