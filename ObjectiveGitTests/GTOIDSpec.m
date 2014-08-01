//
//  GTOIDSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-06-26.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(GTOID)

NSString *testSHA = @"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0";

describe(@"instance", ^{
	__block GTOID *testOID;

	beforeEach(^{
		testOID = [[GTOID alloc] initWithSHA:testSHA];
		expect(testOID).notTo.beNil();
		expect(testOID.SHA).to.equal(testSHA);
	});

	it(@"should expose the git_oid", ^{
		expect(testOID.git_oid).notTo.beNil();
		expect(testOID).to.equal([[GTOID alloc] initWithGitOid:testOID.git_oid]);
	});

	it(@"should compare equal to an OID created with the same SHA", ^{
		expect(testOID).to.equal([[GTOID alloc] initWithSHA:testSHA]);
	});

	it(@"should compare unequal to a different OID", ^{
		NSString *secondSHA = @"82dc47f6ba3beecab33080a1136d8913098e1801";
		expect(testOID).notTo.equal([[GTOID alloc] initWithSHA:secondSHA]);
	});

	it(@"should compare equal to an OID created with the same SHA from a C string", ^{
		expect(testOID).to.equal([[GTOID alloc] initWithSHACString:"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0"]);
	});
});

it(@"should keep the git_oid alive even if the object goes out of scope", ^{
	const git_oid *git_oid = NULL;

	{
		GTOID *testOID __attribute__((objc_precise_lifetime)) = [[GTOID alloc] initWithSHA:testSHA];
		git_oid = testOID.git_oid;
	}

	GTOID *testOID = [[GTOID alloc] initWithGitOid:git_oid];
	expect(testOID.SHA).to.equal(testSHA);
});

it(@"should return an error when initialized with an empty SHA string", ^{
	NSError *error = nil;
	GTOID *oid = [[GTOID alloc] initWithSHA:@"" error:&error];

	expect(oid).to.beNil();
	expect(error).notTo.beNil();
});

it(@"should return an error when initialized with a string that contains non-hex characters", ^{
	NSError *error = nil;
	GTOID *oid = [[GTOID alloc] initWithSHA:@"zzzzz8f4404d3a388efbff6711f1bdf28ffd16a0" error:&error];

	expect(oid).to.beNil();
	expect(error).notTo.beNil();
});

it(@"should return an error when initialized with a string shorter than 40 characters", ^{
	NSError *error = nil;
	GTOID *oid = [[GTOID alloc] initWithSHA:@"f7ecd80" error:&error];

	expect(oid).to.beNil();
	expect(error).notTo.beNil();
});

afterEach(^{
	[self tearDown];
});

SpecEnd
