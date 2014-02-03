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
	[blame enumerateHunksUsingBlock:^(GTBlameHunk *hunk, BOOL *stop) {
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

SpecEnd
