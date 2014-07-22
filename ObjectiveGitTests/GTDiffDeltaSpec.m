//
//  GTDiffDeltaSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 7/15/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTDiffDelta.h"
#import "GTDiffPatch.h"

SpecBegin(GTDiffDelta)

__block GTRepository *repository;
__block GTDiffDelta *delta;

beforeEach(^{
	repository = [self testAppFixtureRepository];
});

describe(@"blob-to-blob diffing", ^{
	beforeEach(^{
		GTBlob *blob1 = [repository lookUpObjectBySHA:@"847cd4b33f4e33bc413468bab016303b50d26d95" error:NULL];
		expect(blob1).notTo.beNil();

		GTBlob *blob2 = [repository lookUpObjectBySHA:@"6060bdeee91b02cb56d9826b4208e9b34122f3f1" error:NULL];
		expect(blob2).notTo.beNil();

		delta = [GTDiffDelta diffDeltaFromBlob:blob1 forPath:@"README1.txt" toBlob:blob2 forPath:@"README1.txt" options:nil error:NULL];
		expect(delta).notTo.beNil();
	});

	it(@"should generate a patch", ^{
		GTDiffPatch *patch = [delta generatePatch:NULL];
		expect(patch).notTo.beNil();
		expect(patch.hunkCount).to.equal(1);
		expect(patch.addedLinesCount).to.equal(1);
		expect(patch.deletedLinesCount).to.equal(1);
	});
});

describe(@"blob-to-data diffing", ^{
	beforeEach(^{
		GTBlob *blob = [repository lookUpObjectBySHA:@"847cd4b33f4e33bc413468bab016303b50d26d95" error:NULL];
		expect(blob).notTo.beNil();

		NSData *data = [@"hello, world" dataUsingEncoding:NSUTF8StringEncoding];

		delta = [GTDiffDelta diffDeltaFromBlob:blob forPath:@"README" toData:data forPath:@"README" options:nil error:NULL];
		expect(delta).notTo.beNil();
	});

	it(@"should generate a patch", ^{
		GTDiffPatch *patch = [delta generatePatch:NULL];
		expect(patch).notTo.beNil();
		expect(patch.hunkCount).to.equal(1);
		expect(patch.addedLinesCount).to.equal(1);
		expect(patch.deletedLinesCount).to.equal(26);
	});
});

describe(@"data-to-data diffing", ^{
	beforeEach(^{
		NSData *data1 = [@"hello world!\nwhat's up" dataUsingEncoding:NSUTF8StringEncoding];
		NSData *data2 = [@"hello, world" dataUsingEncoding:NSUTF8StringEncoding];
		delta = [GTDiffDelta diffDeltaFromData:data1 forPath:@"README" toData:data2 forPath:@"README" options:nil error:NULL];
		expect(delta).notTo.beNil();
	});

	it(@"should generate a patch", ^{
		GTDiffPatch *patch = [delta generatePatch:NULL];
		expect(patch).notTo.beNil();
		expect(patch.hunkCount).to.equal(1);
		expect(patch.addedLinesCount).to.equal(1);
		expect(patch.deletedLinesCount).to.equal(2);
	});
});

SpecEnd
