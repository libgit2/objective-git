//
//  GTRemoteSpec.m
//  ObjectiveGitFramework
//
//  Created by Alan Rogers on 16/10/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRemote.h"

SpecBegin(GTRemote)

__block GTRemote *remote = nil;
__block GTRepository *repository = nil;
NSString *fetchRefspec = @"+refs/heads/*:refs/remotes/origin/*";

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo.beNil();

	NSError *error = nil;
	GTConfiguration *configuration = [repository configurationWithError:&error];
	expect(configuration).toNot.beNil();
	expect(error).to.beNil();

	expect(configuration.remotes.count).to.beGreaterThanOrEqualTo(1);

	remote = configuration.remotes[0];
	expect(remote.name).to.equal(@"origin");
});

describe(@"properties", ^{
	it(@"should have values", ^{
		expect(remote.git_remote).toNot.beNil();
		expect(remote.name).to.equal(@"origin");
		expect(remote.URLString).to.equal(@"git@github.com:github/Test_App.git");

		expect(remote.fetchRefspecs).to.equal(@[ fetchRefspec ]);
	});
});

describe(@"updating", ^{
	it(@"URL string", ^{
		expect(remote.URLString).to.equal(@"git@github.com:github/Test_App.git");

		NSString *newURLString = @"https://github.com/github/Test_App.git";

		__block NSError *error = nil;
		expect([remote updateURLString:newURLString error:&error]).to.beTruthy();
		expect(error).to.beNil();

		expect(remote.URLString).to.equal(newURLString);
	});

	it(@"fetch refspecs", ^{
		expect(remote.fetchRefspecs).to.equal(@[ fetchRefspec ]);

		__block NSError *error = nil;
		expect([remote removeFetchRefspec:fetchRefspec error:&error]).to.beTruthy();
		expect(error).to.beNil();

		expect(remote.fetchRefspecs.count).to.equal(0);

		NSString *newFetchRefspec = @"+refs/heads/master:refs/remotes/origin/master";
		expect([remote addFetchRefspec:newFetchRefspec error:&error]).to.beTruthy();
		expect(error).to.beNil();

		expect(remote.fetchRefspecs).to.equal(@[ newFetchRefspec ]);
	});
});

SpecEnd
