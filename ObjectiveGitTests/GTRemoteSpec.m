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
NSString *fetchRefSpec = @"+refs/heads/*:refs/remotes/origin/*";

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo.beNil();

	NSError *error = nil;
	GTConfiguration *configuration = [repository configurationWithError:&error];
	expect(configuration).toNot.beNil();
	expect(error).to.beNil();

	expect(configuration.remotes.count).to.beGreaterThanOrEqualTo(1);

	remote = configuration.remotes[0];
	expect(remote).toNot.beNil();
});

describe(@"properties", ^{
	it(@"should have values", ^{
		expect(remote.git_remote).toNot.beNil();

		expect(remote.name).to.equal(@"origin");

		expect(remote.URLString).to.equal(@"git@github.com:github/Test_App.git");

		expect(remote.fetchRefSpecs.count).to.equal(1);

		expect(remote.fetchRefSpecs[0]).to.equal(@"+refs/heads/*:refs/remotes/origin/*");
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
		expect(remote.fetchRefSpecs.count).to.equal(1);
		expect(remote.fetchRefSpecs[0]).to.equal(fetchRefSpec);

		__block NSError *error = nil;
		expect([remote removeFetchRefSpec:fetchRefSpec error:&error]).to.beTruthy();
		expect(error).to.beNil();

		expect(remote.fetchRefSpecs.count).to.equal(0);

		NSString *newFetchRefSpec = @"+refs/heads/master:refs/remotes/origin/master";
		expect([remote addFetchRefSpec:newFetchRefSpec error:&error]).to.beTruthy();
		expect(error).to.beNil();

		expect(remote.fetchRefSpecs.count).to.equal(1);

		expect(remote.fetchRefSpecs[0]).to.equal(newFetchRefSpec);
	});

});

SpecEnd
