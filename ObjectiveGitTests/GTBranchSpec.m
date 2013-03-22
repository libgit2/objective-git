//
//  GTBranchSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/22/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTBranch.h"

SpecBegin(GTBranch)

describe(@"-calculateAhead:behind:relativeTo:error:", ^{
	it(@"should report the right numbers", ^{
		GTRepository *repository = [self fixtureRepositoryNamed:@"Test_App"];
		expect(repository).notTo.beNil();

		GTBranch *currentBranch = [repository currentBranchWithError:NULL];
		expect(currentBranch).notTo.beNil();
		expect(currentBranch.shortName).to.equal(@"master");

		GTBranch *trackingBranch = [currentBranch trackingBranchWithError:NULL success:NULL];
		expect(trackingBranch).notTo.beNil();

		size_t ahead = 0;
		size_t behind = 0;
		[currentBranch calculateAhead:&ahead behind:&behind relativeTo:trackingBranch error:NULL];
		expect(ahead).to.equal(9);
		expect(behind).to.equal(0);
	});
});

SpecEnd
