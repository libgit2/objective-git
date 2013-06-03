//
//  GTBranchSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/22/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTBranch.h"

SpecBegin(GTBranch)

__block GTRepository *repository;
__block GTBranch *masterBranch;
__block GTBranch *trackingBranch;

beforeEach(^{
	repository = [self fixtureRepositoryNamed:@"Test_App"];
	expect(repository).notTo.beNil();

	NSError *error = nil;
	masterBranch = [repository currentBranchWithError:&error];
	expect(masterBranch).notTo.beNil();
	expect(error).to.beNil();

	BOOL success = NO;
	trackingBranch = [masterBranch trackingBranchWithError:&error success:&success];
	expect(trackingBranch).notTo.equal(masterBranch);
	expect(success).to.beTruthy();
	expect(error).to.beNil();
});

describe(@"shortName", ^{
	it(@"should use just the branch name for a local branch", ^{
		expect(masterBranch.shortName).to.equal(@"master");
	});

	it(@"should not include the remote name for a tracking branch", ^{
		expect(trackingBranch.shortName).to.equal(@"master");
	});
});

describe(@"remoteName", ^{
	it(@"should return nil for a local branch", ^{
		expect(masterBranch.remoteName).to.beNil();
	});

	it(@"should return the remote name for a tracking branch", ^{
		expect(trackingBranch.remoteName).to.equal(@"origin");
	});
});

describe(@"branchType", ^{
	it(@"should be GTBranchTypeLocal for a local branch", ^{
		expect(masterBranch.branchType).to.equal(GTBranchTypeLocal);
	});

	it(@"should be GTBranchTypeRemote for a tracking branch", ^{
		expect(trackingBranch.branchType).to.equal(GTBranchTypeRemote);
	});
});

describe(@"-calculateAhead:behind:relativeTo:error:", ^{
	it(@"should report the right numbers", ^{
		size_t ahead = 0;
		size_t behind = 0;
		[masterBranch calculateAhead:&ahead behind:&behind relativeTo:trackingBranch error:NULL];
		expect(ahead).to.equal(9);
		expect(behind).to.equal(0);
	});
});

SpecEnd
