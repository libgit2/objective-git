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
	NSURL *indexURL = [self.bareFixtureRepository.gitDirectoryURL URLByAppendingPathComponent:@"index"];
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
	GTRepository *repository = self.bareFixtureRepository;
	GTIndex *index = [repository indexWithError:NULL];
	GTTree *tree = [index writeTree:NULL];
	expect(tree).notTo.beNil();
	expect(tree.entryCount).to.equal(2);
	expect(tree.repository).to.equal(repository);
});

describe(@"conflict enumeration", ^{
	it(@"should correctly find no conflicts", ^{
		expect(index.hasConflicts).to.beFalsy();
	});
	
	it(@"should immediately return YES when enumerating no conflicts", ^{
		__block BOOL blockRan = NO;
		BOOL enumerationResult = [index enumerateConflictedFilesWithError:NULL usingBlock:^(GTIndexEntry *ancestor, GTIndexEntry *ours, GTIndexEntry *theirs, BOOL *stop) {
			blockRan = YES;
		}];
		expect(enumerationResult).to.beTruthy();
		expect(blockRan).to.beFalsy();
	});
	
	it(@"should correctly report conflicts", ^{
		index = [self.conflictedFixtureRepository indexWithError:NULL];
		expect(index).notTo.beNil();
		expect(index.hasConflicts).to.beTruthy();
	});
	
	it(@"should enumerate conflicts successfully", ^{
		index = [self.conflictedFixtureRepository indexWithError:NULL];
		expect(index).notTo.beNil();
		
		NSError *err = NULL;
		__block NSUInteger count = 0;
		NSArray *expectedPaths = @[ @"TestAppDelegate.h", @"main.m" ];
		BOOL enumerationResult = [index enumerateConflictedFilesWithError:&err usingBlock:^(GTIndexEntry *ancestor, GTIndexEntry *ours, GTIndexEntry *theirs, BOOL *stop) {
			expect(ours.path).to.equal(expectedPaths[count]);
			count ++;
		}];
		
		expect(enumerationResult).to.beTruthy();
		expect(err).to.beNil();
		expect(count).to.equal(2);
	});
});

it(@"can update the Index", ^{
	index = [self.testAppFixtureRepository indexWithError:NULL];
	NSString *fileName = @"REAME_";
	NSString *filePath = [self.testAppFixtureRepository.fileURL.path stringByAppendingPathComponent:fileName];
	[@"The wild west..." writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:NULL];
	
	expect(index).toNot.beNil;
	expect([index.repository statusForFile:[NSURL URLWithString:fileName] success:NULL error:NULL]).equal(GTFileStatusModifiedInWorktree);
	
	BOOL success = [index updateEntireIndex:@[fileName] usingBlock:^NSInteger(NSString *path, NSString *matchedPathspec) {
		expect(path).equal(fileName);
		expect(matchedPathspec).equal(fileName);
		return 0;
	} error:NULL];
	
	expect(success).to.beTruthy();
	expect([index.repository statusForFile:[NSURL URLWithString:fileName] success:NULL error:NULL]).equal(GTFileStatusModifiedInIndex);

});
   
SpecEnd
