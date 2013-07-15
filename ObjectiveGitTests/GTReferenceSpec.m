//
//  GTReferenceSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-06-03.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(GTReference)

__block GTRepository *repository;

beforeEach(^{
	repository = [self fixtureRepositoryNamed:@"Test_App"];
	expect(repository).notTo.beNil();
});

it(@"should compare equal to the same reference", ^{
	expect([[GTReference alloc] initByLookingUpReferenceNamed:@"refs/heads/master" inRepository:repository error:NULL]).to.equal([[GTReference alloc] initByLookingUpReferenceNamed:@"refs/heads/master" inRepository:repository error:NULL]);
});

it(@"should compare unequal to a different reference", ^{
	expect([[GTReference alloc] initByLookingUpReferenceNamed:@"refs/heads/master" inRepository:repository error:NULL]).notTo.equal([[GTReference alloc] initByLookingUpReferenceNamed:@"refs/remotes/origin/master" inRepository:repository error:NULL]);
});

describe(@"remote property", ^{
	it(@"should be YES for a remote-tracking branch", ^{
		NSError *error = nil;
		GTReference *ref = [[GTReference alloc] initByLookingUpReferenceNamed:@"refs/remotes/origin/master" inRepository:repository error:&error];
		expect(ref).notTo.beNil();
		expect(error).to.beNil();

		expect(ref.OID.SHA).to.equal(@"d603d61ea756eb881ba440b3e66b561d070aec6e");
		expect(ref.remote).to.beTruthy();
	});

	it(@"should be NO for a local branch", ^{
		NSError *error = nil;
		GTReference *ref = [[GTReference alloc] initByLookingUpReferenceNamed:@"refs/heads/master" inRepository:repository error:&error];
		expect(ref).notTo.beNil();
		expect(error).to.beNil();

		expect(ref.OID.SHA).to.equal(@"a4bca6b67a5483169963572ee3da563da33712f7");
		expect(ref.remote).to.beFalsy();
	});
});

describe(@"transformations", ^{
	static NSString * const testRefName = @"refs/heads/unit_test";
	static NSString * const testRefTarget = @"36060c58702ed4c2a40832c51758d5344201d89a";

	__block GTReference *reference;

	beforeEach(^{
		GTRepository *repository = [self fixtureRepositoryNamed:@"testrepo.git"];
		expect(repository).notTo.beNil();

		NSError *error;
		reference = [GTReference referenceByCreatingReferenceNamed:testRefName fromReferenceTarget:testRefTarget inRepository:repository error:&error];
		expect(reference).notTo.beNil();
		expect(reference.name).to.equal(testRefName);
		expect(reference.targetSHA).to.equal(testRefTarget);
	});

	it(@"should be able to be renamed", ^{
		static NSString * const newRefName = @"refs/heads/new_name";
		GTReference *renamedRef = [reference referenceByRenaming:newRefName error:NULL];
		expect(renamedRef).notTo.beNil();
		expect(renamedRef.name).to.equal(newRefName);
		expect(renamedRef.targetSHA).to.equal(testRefTarget);
	});

	it(@"should be able to change the target", ^{
		static NSString * const newRefTarget = @"5b5b025afb0b4c913b4c338a42934a3863bf3644";
		GTReference *updatedRef = [reference referenceByUpdatingTarget:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" error:NULL];
		expect(updatedRef).notTo.beNil();
		expect(updatedRef.name).to.equal(testRefName);
		expect(updatedRef.targetSHA).to.equal(newRefTarget);
	});
});

describe(@"valid names",^{
	it(@"should accept uppercase top-level names", ^{
		expect([GTReference isValidReferenceName:@"HEAD"]).to.beTruthy();
		expect([GTReference isValidReferenceName:@"ORIG_HEAD"]).to.beTruthy();
	});

	it(@"should not accept lowercase top-level names",^{
		expect([GTReference isValidReferenceName:@"head"]).notTo.beTruthy();
	});

	it(@"should accept names with the refs/ prefix",^{
		expect([GTReference isValidReferenceName:@"refs/stuff"]).to.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/multiple/components"]).to.beTruthy();
	});

	it(@"should not accept names with invalid parts",^{
		expect([GTReference isValidReferenceName:@"refs/stuff~"]).notTo.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/stuff^"]).notTo.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/stuff:"]).notTo.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/stuff\\"]).notTo.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/stuff?"]).notTo.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/stuff["]).notTo.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/stuff*"]).notTo.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/stuff.."]).notTo.beTruthy();
		expect([GTReference isValidReferenceName:@"refs/stuff@{"]).notTo.beTruthy();
	});
});

SpecEnd
