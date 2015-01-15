//
//  GTBlameSpec.m
//  ObjectiveGitFramework
//
//  Created by Ezekiel Pierson on 1/24/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTBlameSpec)

__block GTBlame *blame = nil;

qck_beforeEach(^{
	blame = [self.testAppFixtureRepository blameWithFile:@"README1.txt" options:nil error:nil];
	expect(blame).notTo(beNil());
});

qck_it(@"can count the hunks", ^{
	expect(@(blame.hunkCount)).to(equal(@4));
});

qck_it(@"can read hunk properties", ^{
	GTBlameHunk *hunk = [blame hunkAtIndex:1];

	expect(hunk).notTo(beNil());
	expect(@(NSEqualRanges(hunk.lines, NSMakeRange(22, 1)))).to(beTruthy());
	expect(hunk.finalCommitOID.SHA).to(equal(@"82dc47f6ba3beecab33080a1136d8913098e1801"));
	expect(hunk.finalSignature).notTo(beNil());
	expect(hunk.originalPath).to(equal(@"README1.txt"));
	expect(@(hunk.isBoundary)).to(beFalsy());
});

qck_it(@"The number of hunks in the `hunks` array should match `hunkCount`", ^{
	expect(@(blame.hunks.count)).to(equal(@(blame.hunkCount)));
});

qck_it(@"should be able to enumerate all the hunks in a blame, stopping when instructed", ^{
	NSMutableArray *mutableArray = [NSMutableArray array];
	[blame enumerateHunksUsingBlock:^(GTBlameHunk *hunk, NSUInteger index, BOOL *stop) {
		[mutableArray addObject:hunk];
		*stop = YES;
	}];

	expect(@(mutableArray.count)).to(equal(@(1)));
});

qck_it(@"should be able to get the same hunk from an index or a line", ^{
	GTBlameHunk *hunk = [blame hunkAtIndex:0];
	GTBlameHunk *lineHunk = [blame hunkAtLineNumber:1];

	expect(hunk).to(equal(lineHunk));
});

qck_describe(@"Creating a blame with options", ^{
	qck_it(@"should follow the instructions provided by the GTBlameOptionsOldestCommitOID key", ^{
		GTBlame *optionsBlame = [self.testAppFixtureRepository blameWithFile:@"README1.txt" options:@{ GTBlameOptionsOldestCommitOID: [GTOID oidWithSHA:@"1d69f3c0aeaf0d62e25591987b93b8ffc53abd77"] } error:nil];

		expect(optionsBlame).notTo(beNil());
		expect(optionsBlame).notTo(equal(blame));
	});

	qck_it(@"should follow the instructions provided by the GTBlameOptionsNewestCommitOID key", ^{
		GTOID *newOID = [GTOID oidWithSHA:@"6317779b4731d9c837dcc6972b964bdf4211eeef"];
		GTBlame *optionsBlame = [self.testAppFixtureRepository blameWithFile:@"README1.txt" options:@{ GTBlameOptionsNewestCommitOID: newOID } error:nil];

		GTBlameHunk *hunk = [optionsBlame hunkAtIndex:0];
		expect(@(hunk.lines.location)).to(equal(@1));
		expect(@(hunk.lines.length)).to(equal(@25));
	});

	qck_it(@"should follow the instructions provided by GTBlameOptionsFirstLine and GTBlameOptionsLastLine keys", ^{
		GTBlame *optionsBlame = [self.testAppFixtureRepository blameWithFile:@"README1.txt" options:@{ GTBlameOptionsFirstLine: @22, GTBlameOptionsLastLine: @24 } error:nil];
		GTBlameHunk *hunk = [optionsBlame hunkAtIndex:0];

		expect(optionsBlame).notTo(beNil());
		expect(@(hunk.lines.location)).to(equal(@22));
		expect(@(hunk.lines.length)).to(equal(@1));
	});
});

qck_afterEach(^{
	[self tearDown];
});

QuickSpecEnd
