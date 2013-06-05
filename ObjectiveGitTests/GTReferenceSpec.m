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

SpecEnd
