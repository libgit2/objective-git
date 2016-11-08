//
//  Libgit2FeaturesSpec.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 7/6/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <Nimble/Nimble-Swift.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(Libgit2FeaturesSpec)

describe(@"libgit", ^{

	__block git_feature_t git_features = 0;

	beforeEach(^{
		git_features = git_libgit2_features();
	});

	it(@"should be built with THREADS enabled", ^{
		expect(@(git_features & GIT_FEATURE_THREADS)).to(beTruthy());
	});

	it(@"should be built with HTTPS enabled", ^{
		expect(@(git_features & GIT_FEATURE_HTTPS)).to(beTruthy());
	});

	it(@"should be built with SSH enabled", ^{
		expect(@(git_features & GIT_FEATURE_SSH)).to(beTruthy());
	});

});

QuickSpecEnd
