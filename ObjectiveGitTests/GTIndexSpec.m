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

describe(@"updating pathspecs", ^{
	NSString *fileName = @"REAME_";
	beforeEach(^{
		index = [self.testAppFixtureRepository indexWithError:NULL];
		NSString *filePath = [self.testAppFixtureRepository.fileURL.path stringByAppendingPathComponent:fileName];
		[@"The wild west..." writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:NULL];

		expect(index).toNot.beNil();
		expect([index.repository statusForFile:[NSURL URLWithString:fileName] success:NULL error:NULL]).to.equal(GTFileStatusModifiedInWorktree);
	});
	
	it(@"should update the Index", ^{
		BOOL success = [index updatePathspecs:@[ fileName ] error:NULL passingTest:^(NSString *matchedPathspec, NSString *path, BOOL *stop) {
			expect(matchedPathspec).to.equal(fileName);
			expect(path).to.equal(fileName);
			return YES;
		}];
		
		expect(success).to.beTruthy();
		expect([index.repository statusForFile:[NSURL URLWithString:fileName] success:NULL error:NULL]).to.equal(GTFileStatusModifiedInIndex);
	});
	
	it(@"should skip a specific file", ^{
		BOOL success = [index updatePathspecs:NULL error:NULL passingTest:^(NSString *matchedPathspec, NSString *path, BOOL *stop) {
			if ([path.lastPathComponent isEqualToString:fileName]) {
				return NO;
			} else {
				return YES;
			}
		}];
		
		expect(success).to.beTruthy();
		expect([index.repository statusForFile:[NSURL URLWithString:fileName] success:NULL error:NULL]).to.equal(GTFileStatusModifiedInWorktree);
	});
	
	it(@"should stop be able to stop early", ^{
		NSString *otherFileName = @"TestAppDelegate.h";
		[@"WELP" writeToFile:[self.testAppFixtureRepository.fileURL.path stringByAppendingPathComponent:otherFileName] atomically:NO encoding:NSUTF8StringEncoding error:NULL];
		BOOL success = [index updatePathspecs:NULL error:NULL passingTest:^(NSString *matchedPathspec, NSString *path, BOOL *stop) {
			if ([path.lastPathComponent isEqualToString:otherFileName]) {
				*stop = YES;
				return YES;
			}
			return YES;
		}];
		
		expect(success).to.beTruthy();
		expect([index.repository statusForFile:[NSURL URLWithString:otherFileName] success:NULL error:NULL]).to.equal(GTFileStatusModifiedInIndex);
		expect([index.repository statusForFile:[NSURL URLWithString:fileName] success:NULL error:NULL]).to.equal(GTFileStatusModifiedInIndex);
	});
});

SpecEnd
