//
//  GTRepositoryResetSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTRepositoryReset)

__block GTRepository *repository;

describe(@"-resetPathspecs:toCommit:error:", ^{
	__block NSUInteger (^countStagedFiles)(void);

	beforeEach(^{
		repository = [self testAppFixtureRepository];

		countStagedFiles = ^{
			__block NSUInteger count = 0;
			[repository enumerateFileStatusWithOptions:nil error:NULL usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
				if (headToIndex.status != GTDeltaTypeUnmodified) count++;
			}];

			return count;
		};
	});

	it(@"should reset the path's index entry", ^{
		static NSString * const fileName = @"README.md";
		NSURL *fileURL = [repository.fileURL URLByAppendingPathComponent:fileName];
		BOOL success = [@"blahahaha" writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		expect(@(success)).to(beTruthy());

		GTIndex *index = [repository indexWithError:NULL];
		expect(index).notTo(beNil());

		success = [index addFile:fileName error:NULL];
		expect(@(success)).to(beTruthy());

		expect(@(countStagedFiles())).to(equal(@1));

		GTCommit *HEAD = [repository lookUpObjectByRevParse:@"HEAD" error:NULL];
		expect(HEAD).notTo(beNil());

		success = [repository resetPathspecs:@[ fileName ] toCommit:HEAD error:NULL];
		expect(@(success)).to(beTruthy());

		expect(@(countStagedFiles())).to(equal(@0));
	});
});

describe(@"-resetToCommit:resetType:error:", ^{
	beforeEach(^{
		repository = [self bareFixtureRepository];
	});

	it(@"should move HEAD when used", ^{
		NSError *error = nil;
		GTReference *originalHead = [repository headReferenceWithError:NULL];
		NSString *resetTargetSHA = @"8496071c1b46c854b31185ea97743be6a8774479";

		GTCommit *commit = [repository lookUpObjectBySHA:resetTargetSHA error:NULL];
		expect(commit).notTo(beNil());
		GTCommit *originalHeadCommit = [repository lookUpObjectByOID:originalHead.targetOID error:NULL];
		expect(originalHeadCommit).notTo(beNil());

		BOOL success = [repository resetToCommit:commit resetType:GTRepositoryResetTypeSoft error:&error];
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());

		GTReference *head = [repository headReferenceWithError:&error];
		expect(head).notTo(beNil());
		expect(head.targetOID.SHA).to(equal(resetTargetSHA));

		success = [repository resetToCommit:originalHeadCommit resetType:GTRepositoryResetTypeSoft error:&error];
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());

		head = [repository headReferenceWithError:&error];
		expect(head.targetOID).to(equal(originalHead.targetOID));
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
