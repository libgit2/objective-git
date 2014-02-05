//
//  GTBlameSpec.m
//  ObjectiveGitFramework
//
//  Created by Ezekiel Pierson on 1/24/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

SpecBegin(GTBlame)

__block GTBlame *blame = nil;

beforeEach(^{
	blame = [GTBlame blameWithFile:@"README1.txt" inRepository:self.testAppFixtureRepository error:nil];
	expect(blame).toNot.beNil();
});

it(@"can count the hunks", ^{
	expect(blame.hunkCount).to.equal(4);
});

it(@"can read hunk properties", ^{
	GTBlameHunk *hunk = [blame hunkAtIndex:1];
	GTOID *OID = [[GTOID alloc]initWithSHA:@"82dc47f6ba3beecab33080a1136d8913098e1801"];
	
	expect(hunk).notTo.beNil();
	expect(hunk.lineCount).to.equal(1);
	expect(hunk.finalCommitOID).to.equal(OID);
	expect(hunk.finalStartLineNumber).to.equal(22);
	expect(hunk.finalSignature).toNot.beNil();
	expect(hunk.originalCommitOID).to.equal(OID);
	expect(hunk.originalStartLineNumber).to.equal(22);
	expect(hunk.originalSignature).toNot.beNil();
	expect(hunk.originalPath).to.equal(@"README1.txt");
	expect(hunk.isBoundary).to.beFalsy();
});

it(@"should be able to provide all the hunks quickly ", ^{
	expect(blame.hunks).to.haveCountOf(blame.hunkCount);
});

it(@"should be able to enumerate all the hunks in a blame, stopping when instructed", ^{
	NSMutableArray *mutableArray = [NSMutableArray array];
	[blame enumerateHunksUsingBlock:^(GTBlameHunk *hunk, NSUInteger index, BOOL *stop) {
		[mutableArray addObject:hunk];
		*stop = YES;
	}];
	
	expect(mutableArray).to.haveCountOf(1);
});

it(@"should be able to get the same hunk from an index or a line", ^{
	GTBlameHunk *hunk = [blame hunkAtIndex:0];
	GTBlameHunk *lineHunk = [blame hunkAtLineNumber:1];

	expect(hunk).notTo.beNil();
	expect(lineHunk).notTo.beNil();
	expect(hunk).to.equal(lineHunk);
});

describe(@"Creating a blame with options", ^{
	it(@"should follow the instructions provided by the GTBlameOptionsOldestCommitOID key", ^{
		GTOID *oldOID = [GTOID oidWithSHA:@"1d69f3c0aeaf0d62e25591987b93b8ffc53abd77"];
		GTBlame *optionsBlame = [GTBlame blameWithFile:@"README1.txt" inRepository:self.testAppFixtureRepository options:@{GTBlameOptionsOldestCommitOID: oldOID } error:nil];

		expect([optionsBlame hunkAtIndex:0].originalCommitOID).to.equal(oldOID);
		expect([blame hunkAtIndex:0].originalCommitOID).toNot.equal(oldOID);
	});
	
	it(@"should follow the instructions provided by the GTBlameOptionsNewestCommitOID key", ^{
		GTOID *newOID = [GTOID oidWithSHA:@"6317779b4731d9c837dcc6972b964bdf4211eeef"];
		GTBlame *optionsBlame = [GTBlame blameWithFile:@"README1.txt" inRepository:self.testAppFixtureRepository options:@{GTBlameOptionsNewestCommitOID: newOID } error:nil];
		expect(optionsBlame.hunkCount).to.equal(1);
		expect(blame.hunkCount).to.equal(4);
	});
	
	it(@"should follow the instructions provided by the GTBlameOptionsFirstLine key", ^{
		GTBlame *optionsBlame = [GTBlame blameWithFile:@"README1.txt" inRepository:self.testAppFixtureRepository options:@{ GTBlameOptionsFirstLine: @22, GTBlameOptionsLastLine: @24 } error:nil];
		expect(optionsBlame.hunkCount).toNot.equal(blame.hunkCount);
	});
	
	it(@"should follow the instructions provided by the GTBlameOptionsTrackCopiesAnyCommitCopies key", ^{
		GTBlame *optionsBlame = [GTBlame blameWithFile:@"README_renamed" inRepository:self.testAppFixtureRepository options:@{ GTBlameOptionsFlags: @(GTBlameOptionsTrackCopiesAnyCommitCopies) } error:nil];

		[optionsBlame enumerateHunksUsingBlock:^(GTBlameHunk *hunk, NSUInteger index, BOOL *stop) {
			expect(hunk.originalPath).to.equal(@"README");
			// These test should fail when `GTBlameOptionsTrackCopiesAnyCommitCopies` is implemented.
			expect(hunk.finalCommitOID).to.equal(hunk.originalCommitOID);
			expect(hunk.originalSignature).to.equal(hunk.finalSignature);
			expect(hunk.originalStartLineNumber).to.equal(hunk.finalStartLineNumber);
		}];
	});
});

SpecEnd
