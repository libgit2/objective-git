//
//  GTReferenceSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-06-03.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTReferenceSpec)

__block GTRepository *repository;

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo(beNil());
});

it(@"should compare equal to the same reference", ^{
	expect([repository lookUpReferenceWithName:@"refs/heads/master" error:NULL]).to(equal([repository lookUpReferenceWithName:@"refs/heads/master" error:NULL]));
});

it(@"should compare unequal to a different reference", ^{
	expect([repository lookUpReferenceWithName:@"refs/heads/master" error:NULL]).notTo(equal([repository lookUpReferenceWithName:@"refs/remotes/origin/master" error:NULL]));
});

describe(@"remote property", ^{
	it(@"should be YES for a remote-tracking branch", ^{
		NSError *error = nil;
		GTReference *ref = [repository lookUpReferenceWithName:@"refs/remotes/origin/master" error:&error];
		expect(ref).notTo(beNil());
		expect(error).to(beNil());

		expect(ref.OID.SHA).to(equal(@"d603d61ea756eb881ba440b3e66b561d070aec6e"));
		expect(@(ref.remote)).to(beTruthy());
	});

	it(@"should be NO for a local branch", ^{
		NSError *error = nil;
		GTReference *ref = [repository lookUpReferenceWithName:@"refs/heads/master" error:&error];
		expect(ref).notTo(beNil());
		expect(error).to(beNil());

		expect(ref.OID.SHA).to(equal(@"a4bca6b67a5483169963572ee3da563da33712f7"));
		expect(@(ref.remote)).to(beFalsy());
	});
});

describe(@"transformations", ^{
	NSString *testRefName = @"refs/heads/unit_test";
	GTOID *testRefOID = [[GTOID alloc] initWithSHA:@"36060c58702ed4c2a40832c51758d5344201d89a"];

	__block GTReference *reference;

	beforeEach(^{
		GTRepository *repository = self.bareFixtureRepository;
		expect(repository).notTo(beNil());

		NSError *error;
		reference = [repository createReferenceNamed:testRefName fromOID:testRefOID message:nil error:&error];
		expect(reference).notTo(beNil());
		expect(reference.name).to(equal(testRefName));
		expect(reference.targetOID).to(equal(testRefOID));
	});

	it(@"should be able to be renamed", ^{
		NSString *newRefName = @"refs/heads/new_name";

		GTReference *renamedRef = [reference referenceByRenaming:newRefName error:NULL];
		expect(renamedRef).notTo(beNil());
		expect(renamedRef.name).to(equal(newRefName));
		expect(renamedRef.targetOID).to(equal(testRefOID));
	});

	it(@"should be able to change the target", ^{
		NSString *newRefTarget = @"5b5b025afb0b4c913b4c338a42934a3863bf3644";

		GTReference *updatedRef = [reference referenceByUpdatingTarget:newRefTarget message:nil error:NULL];
		expect(updatedRef).notTo(beNil());
		expect(updatedRef.name).to(equal(testRefName));
		expect(updatedRef.targetOID.SHA).to(equal(newRefTarget));
	});
});

describe(@"valid names",^{
	it(@"should accept uppercase top-level names", ^{
		expect(@([GTReference isValidReferenceName:@"HEAD"])).to(beTruthy());
		expect(@([GTReference isValidReferenceName:@"ORIG_HEAD"])).to(beTruthy());
	});

	it(@"should not accept lowercase top-level names",^{
		expect(@([GTReference isValidReferenceName:@"head"])).notTo(beTruthy());
	});

	it(@"should accept names with the refs/ prefix",^{
		expect(@([GTReference isValidReferenceName:@"refs/stuff"])).to(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/multiple/components"])).to(beTruthy());
	});

	it(@"should not accept names with invalid parts",^{
		expect(@([GTReference isValidReferenceName:@"refs/stuff~"])).notTo(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/stuff^"])).notTo(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/stuff:"])).notTo(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/stuff\\"])).notTo(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/stuff?"])).notTo(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/stuff["])).notTo(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/stuff*"])).notTo(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/stuff.."])).notTo(beTruthy());
		expect(@([GTReference isValidReferenceName:@"refs/stuff@{"])).notTo(beTruthy());
	});
});

__block GTRepository *bareRepository;

void (^expectValidReference)(GTReference *ref, NSString *SHA, GTReferenceType type, NSString *name) = ^(GTReference *ref, NSString *SHA, GTReferenceType type, NSString *name) {
	expect(ref).notTo(beNil());
	expect(ref.targetOID.SHA).to(equal(SHA));
	expect(@(ref.referenceType)).to(equal(@(type)));
	expect(ref.name).to(equal(name));
};

beforeEach(^{
	bareRepository = self.bareFixtureRepository;
});

describe(@"+referenceByLookingUpReferenceNamed:inRepository:error:", ^{
	it(@"should return a valid reference to a branch", ^{
		NSError *error = nil;
		GTReference *ref = [bareRepository lookUpReferenceWithName:@"refs/heads/master" error:&error];
		expect(ref).notTo(beNil());
		expect(error).to(beNil());

		expectValidReference(ref, @"36060c58702ed4c2a40832c51758d5344201d89a", GTReferenceTypeOid, @"refs/heads/master");
	});

	it(@"should return a valid reference to a tag", ^{
		NSError *error = nil;
		GTReference *ref = [bareRepository lookUpReferenceWithName:@"refs/tags/v0.9" error:&error];
		expect(ref).notTo(beNil());
		expect(error).to(beNil());

		expectValidReference(ref, @"5b5b025afb0b4c913b4c338a42934a3863bf3644", GTReferenceTypeOid, @"refs/tags/v0.9");
	});
});

describe(@"creating", ^{
	it(@"can create a reference from a symbolic reference", ^{
		GTReference *target = [bareRepository lookUpReferenceWithName:@"refs/heads/master" error:NULL];
		expect(target).notTo(beNil());

		NSError *error = nil;
		GTReference *ref = [bareRepository createReferenceNamed:@"refs/heads/unit_test" fromReference:target message:nil error:&error];
		expect(error).to(beNil());
		expect(ref).notTo(beNil());

		expectValidReference(ref, @"36060c58702ed4c2a40832c51758d5344201d89a", GTReferenceTypeSymbolic, @"refs/heads/unit_test");
		expect(ref.resolvedReference.name).to(equal(@"refs/heads/master"));
	});

	it(@"can create a reference from an SHA/OID", ^{
		GTOID *target = [[GTOID alloc] initWithSHA:@"36060c58702ed4c2a40832c51758d5344201d89a"];

		NSError *error = nil;
		GTReference *ref = [bareRepository createReferenceNamed:@"refs/heads/unit_test" fromOID:target message:nil error:&error];
		expect(error).to(beNil());
		expect(ref).notTo(beNil());

		expectValidReference(ref, @"36060c58702ed4c2a40832c51758d5344201d89a", GTReferenceTypeOid, @"refs/heads/unit_test");
	});
});

describe(@"-deleteWithError:", ^{
	it(@"can delete references", ^{
		GTOID *target = [[GTOID alloc] initWithSHA:@"36060c58702ed4c2a40832c51758d5344201d89a"];

		NSError *error = nil;
		GTReference *ref = [bareRepository createReferenceNamed:@"refs/heads/unit_test" fromOID:target message:nil error:&error];

		expect(error).to(beNil());
		expect(ref).notTo(beNil());

		BOOL success = [ref deleteWithError:&error];
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
