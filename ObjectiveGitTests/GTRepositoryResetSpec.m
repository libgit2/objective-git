//
//  GTRepositoryResetSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/7/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Reset.h"
#import "GTRepository.h"
#import "GTIndex.h"

SpecBegin(GTRepositoryReset)

fdescribe(@"-resetPaths:toCommit:error:", ^{
	__block GTRepository *repository;
	__block NSUInteger (^countStagedFiles)(void);

	beforeEach(^{
		repository = [self testAppFixtureRepository];

		countStagedFiles = ^{
			__block NSUInteger count = 0;
			[repository enumerateFileStatusWithOptions:Nil error:NULL usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
				if (headToIndex.status != GTStatusDeltaStatusUnmodified) count++;
			}];

			return count;
		};
	});

	it(@"should reset the path's index entry", ^{
		static NSString * const fileName = @"README.md";
		NSURL *fileURL = [repository.fileURL URLByAppendingPathComponent:fileName];
		BOOL success = [@"blahahaha" writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		expect(success).to.beTruthy();

		GTIndex *index = [repository indexWithError:NULL];
		expect(index).notTo.beNil();

		success = [index addFile:fileName error:NULL];
		expect(success).to.beTruthy();

		expect(countStagedFiles()).to.equal(1);

		GTCommit *HEAD = [repository lookUpObjectByRevParse:@"HEAD" error:NULL];
		expect(HEAD).notTo.beNil();

		success = [repository resetPaths:@[ fileName ] toCommit:HEAD error:NULL];
		expect(success).to.beTruthy();

		expect(countStagedFiles()).to.equal(0);
	});
});

SpecEnd
