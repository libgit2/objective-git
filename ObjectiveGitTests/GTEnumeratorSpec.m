//
//  GTEnumeratorSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-05-28.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTEnumerator.h"

SpecBegin(GTEnumerator)

__block GTRepository *repo;
__block GTEnumerator *enumerator;

beforeEach(^{
	NSError *error = nil;
	repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	expect(repo).notTo.beNil();
	expect(error).to.beNil();

	enumerator = repo.enumerator;
	expect(enumerator).notTo.beNil();
});

it(@"should walk from repository HEAD", ^{
	NSError *error = nil;

	__block NSUInteger count = 0;
    [repo enumerateCommitsBeginningAtSha:nil error:&error usingBlock:^(GTCommit *commit, BOOL *stop) {
        count++;
    }];

	expect(count).to.equal(3);
	expect(error).to.beNil();
});

describe(@"with a rev list", ^{
	__block NSMutableArray *expectedSHAs;
	__block void (^verifyEnumerator)(void);
	
	beforeEach(^{
		expectedSHAs = [@[
			@"9fd738e8f7967c078dceed8190330fc8648ee56a",
			@"4a202b346bb0fb0db7eff3cffeb3c70babbd2045",
			@"5b5b025afb0b4c913b4c338a42934a3863bf3644",
			@"8496071c1b46c854b31185ea97743be6a8774479",
		] mutableCopy];

		verifyEnumerator = ^{
			__block NSError *error = nil;
			expect([enumerator pushSHA:expectedSHAs[0] error:&error]).to.beTruthy();
			expect(error).to.beNil();

			NSMutableArray *SHAs = [NSMutableArray array];
			for (GTCommit *commit in enumerator) {
				expect(commit).to.beKindOf(GTCommit.class);
				[SHAs addObject:commit.sha];
			}

			expect(SHAs).to.equal(expectedSHAs);

			expect([enumerator nextObjectWithError:&error]).to.beNil();
			expect(error).to.beNil();
		};
	});

	it(@"should walk the whole list", ^{
		verifyEnumerator();
	});

	it(@"should walk part of a rev list", ^{
		[expectedSHAs removeObjectsInRange:NSMakeRange(0, expectedSHAs.count - 1)];
		verifyEnumerator();
	});

	it(@"should hide a SHA", ^{
		__block NSError *error = nil;
		expect([enumerator skipSHA:expectedSHAs[2] error:&error]).to.beTruthy();
		expect(error).to.beNil();

		[expectedSHAs removeObjectsInRange:NSMakeRange(2, expectedSHAs.count - 2)];
		verifyEnumerator();
	});

	it(@"should reset", ^{
		verifyEnumerator();
		[enumerator reset];
		verifyEnumerator();
	});
});

SpecEnd
