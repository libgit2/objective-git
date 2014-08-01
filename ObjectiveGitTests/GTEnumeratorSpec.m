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
	repo = self.bareFixtureRepository;
	expect(repo).notTo.beNil();

	enumerator = [[GTEnumerator alloc] initWithRepository:repo error:NULL];
	expect(enumerator).notTo.beNil();
});

it(@"should walk from repository HEAD", ^{
	NSError *error = nil;

	GTReference *HEADRef = [repo headReferenceWithError:NULL];
	expect(HEADRef).notTo.beNil();
	
	[enumerator pushSHA:HEADRef.targetSHA error:NULL];
	NSUInteger count = [enumerator allObjects].count;
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
				[SHAs addObject:commit.SHA];
			}

			expect(SHAs).to.equal(expectedSHAs);

			__block BOOL success;
			expect([enumerator nextObjectWithSuccess:&success error:&error]).to.beNil();
			expect(success).to.beTruthy();
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
		expect([enumerator hideSHA:expectedSHAs[2] error:&error]).to.beTruthy();
		expect(error).to.beNil();

		[expectedSHAs removeObjectsInRange:NSMakeRange(2, expectedSHAs.count - 2)];
		verifyEnumerator();
	});

	it(@"should reset with options", ^{
		expect(enumerator.options).to.equal(GTEnumeratorOptionsNone);
		verifyEnumerator();

		[enumerator resetWithOptions:GTEnumeratorOptionsTimeSort];

		expect(enumerator.options).to.equal(GTEnumeratorOptionsTimeSort);
		verifyEnumerator();
	});
});

describe(@"globbing", ^{
	NSString *branchGlob = @"refs/heads/m*t*r";

	__block NSMutableArray *expectedSHAs;
	__block void (^verifyEnumerator)(void);
	
	beforeEach(^{
		expectedSHAs = [@[
			@"36060c58702ed4c2a40832c51758d5344201d89a",
			@"5b5b025afb0b4c913b4c338a42934a3863bf3644",
			@"8496071c1b46c854b31185ea97743be6a8774479",
		] mutableCopy];

		verifyEnumerator = ^{
			NSMutableArray *SHAs = [NSMutableArray array];
			for (GTCommit *commit in enumerator) {
				[SHAs addObject:commit.SHA];
			}

			expect(SHAs).to.equal(expectedSHAs);

			__block NSError *error = nil;
			__block BOOL success;
			expect([enumerator nextObjectWithSuccess:&success error:&error]).to.beNil();
			expect(success).to.beTruthy();
			expect(error).to.beNil();
		};
	});

	it(@"should push a glob", ^{
		__block NSError *error = nil;
		expect([enumerator pushGlob:branchGlob error:&error]).to.beTruthy();
		expect(error).to.beNil();
		
		verifyEnumerator();
	});

	it(@"should hide a glob", ^{
		__block NSError *error = nil;
		expect([enumerator pushSHA:expectedSHAs[0] error:&error]).to.beTruthy();
		expect(error).to.beNil();

		expect([enumerator hideGlob:branchGlob error:&error]).to.beTruthy();
		expect(error).to.beNil();
		
		[expectedSHAs removeAllObjects];
		verifyEnumerator();
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
