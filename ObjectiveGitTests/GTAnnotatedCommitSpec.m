//
//  GTAnnotatedCommitSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 28/10/2019.
//  Copyright (c) 2019 GitHub, Inc. All rights reserved.
//

@import ObjectiveGit;
@import Nimble;
@import Quick;

#import "QuickSpec+GTFixtures.h"

#define MASTER_OID @"a4bca6b67a5483169963572ee3da563da33712f7"

QuickSpecBegin(GTAnnotatedCommitSpec)

__block GTRepository *repository;
__block GTIndex *index;

beforeEach(^{
	repository = self.testAppFixtureRepository;

	index = [repository indexWithError:NULL];
	expect(index).notTo(beNil());

	BOOL success = [index refresh:NULL];
	expect(@(success)).to(beTruthy());
});

describe(@"initialization", ^{
	it(@"can be initialized from a reference", ^{
		NSError *error = nil;

		GTReference *ref = [repository lookUpReferenceWithName:@"refs/heads/master" error:NULL];
		expect(ref).notTo(beNil());

		GTAnnotatedCommit *commit = [GTAnnotatedCommit annotatedCommitFromReference:ref error:&error];
		expect(commit).notTo(beNil());
		expect(error).to(beNil());

		expect(commit.OID.SHA).to(equal(MASTER_OID));
	});

	it(@"can be initialized from a fetch head", ^{
		NSError *error = nil;

		GTOID *oid = [GTOID oidWithSHA:MASTER_OID];

		GTAnnotatedCommit *commit = [GTAnnotatedCommit annotatedCommitFromFetchHead:@"master"
																				url:@"https://example.com/random.git"
																				oid:oid
																	   inRepository:repository
																			  error:&error];
		expect(commit).notTo(beNil());
		expect(error).to(beNil());

		expect(commit.OID.SHA).to(equal(MASTER_OID));
	});

	it(@"can be initialized from an OID", ^{
		NSError *error = nil;

		GTReference *ref = [repository headReferenceWithError:NULL];
		expect(ref).notTo(beNil());

		GTAnnotatedCommit *commit = [GTAnnotatedCommit annotatedCommitFromOID:ref.OID
																 inRepository:repository
																		error:&error];
		expect(commit).notTo(beNil());
		expect(error).to(beNil());

		expect(commit.OID.SHA).to(equal(MASTER_OID));

	});

	it(@"can be initialized from a revspec", ^{
		NSError *error = nil;

		GTAnnotatedCommit *commit = [GTAnnotatedCommit annotatedCommitFromRevSpec:@"master^"
																	 inRepository:repository
																			error:&error];
		expect(commit).notTo(beNil());
		expect(error).to(beNil());

		expect(commit.OID.SHA).to(equal(@"6b0c1c8b8816416089c534e474f4c692a76ac14f"));
	});
});


afterEach(^{
	[self tearDown];
});

QuickSpecEnd
