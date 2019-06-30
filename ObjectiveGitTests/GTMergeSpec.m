//
//  GTMerge.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 26/10/2018.
//  Copyright © 2018 GitHub, Inc. All rights reserved.
//


@import ObjectiveGit;
@import Nimble;
@import Quick;

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTMergeSpec)

__block GTRepository *repository;
__block GTIndex *index;

beforeEach(^{
	repository = self.testAppFixtureRepository;

	index = [repository indexWithError:NULL];
	expect(index).notTo(beNil());

	BOOL success = [index refresh:NULL];
	expect(@(success)).to(beTruthy());
});

describe(@"+performMergeWithAncestor:ourFile:theirFile:options:error:", ^{
	it(@"can merge conflicting strings", ^{
		GTMergeFile *ourFile = [GTMergeFile fileWithString:@"A test string\n" path:@"ours.txt" mode:0];
		GTMergeFile *theirFile = [GTMergeFile fileWithString:@"A better test string\n" path:@"theirs.txt" mode:0];
		GTMergeFile *ancestorFile = [GTMergeFile fileWithString:@"A basic string\n" path:@"ancestor.txt" mode:0];

		NSError *error = nil;
		GTMergeResult *result = [GTMergeFile performMergeWithAncestor:ancestorFile ourFile:ourFile theirFile:theirFile options:nil error:&error];
		expect(result).notTo(beNil());
		expect(error).to(beNil());

		expect(result.isAutomergeable).to(beFalse());
		expect(result.path).to(beNil());
		expect(result.mode).to(equal(@(GTFileModeBlob)));
		NSString *mergedString = [[NSString alloc] initWithData:result.data encoding:NSUTF8StringEncoding];
		expect(mergedString).to(equal(@"<<<<<<< ours.txt\n"
									  "A test string\n"
									  "=======\n"
									  "A better test string\n"
									  ">>>>>>> theirs.txt\n"));
	});

	it(@"can merge non-conflicting files", ^{
		GTMergeFile *ourFile = [GTMergeFile fileWithString:@"A test string\n" path:@"ours.txt" mode:0];
		GTMergeFile *theirFile = [GTMergeFile fileWithString:@"A better test string\n" path:@"theirs.txt" mode:0];
		GTMergeFile *ancestorFile = [GTMergeFile fileWithString:@"A test string\n" path:@"ancestor.txt" mode:0];

		NSError *error = nil;
		GTMergeResult *result = [GTMergeFile performMergeWithAncestor:ancestorFile ourFile:ourFile theirFile:theirFile options:nil error:&error];
		expect(result).notTo(beNil());
		expect(error).to(beNil());

		expect(result.isAutomergeable).to(beTrue());
		expect(result.path).to(beNil());
		expect(result.mode).to(equal(@(GTFileModeBlob)));
		NSString *mergedString = [[NSString alloc] initWithData:result.data encoding:NSUTF8StringEncoding];
		expect(mergedString).to(equal(@"A better test string\n"));
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
