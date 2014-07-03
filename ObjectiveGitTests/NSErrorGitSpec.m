//
//  NSErrorGitSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-08-23.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSError+Git.h"

SpecBegin(NSErrorGit)

it(@"should create an error with a nil description", ^{
	NSError *error = [NSError git_errorFor:GIT_OK description:nil];
	expect(error).notTo.beNil();

	expect(error.domain).to.equal(GTGitErrorDomain);
	expect(error.code).to.equal(GIT_OK);

	// Test the keys because NSError adds its own defaults sometimes.
	expect(error.userInfo[NSLocalizedDescriptionKey]).to.beNil();
	expect(error.userInfo[NSLocalizedFailureReasonErrorKey]).to.beNil();
});

it(@"should create an error with a formatted description", ^{
	NSError *error = [NSError git_errorFor:GIT_OK description:@"foo %@ bar %@", @1, @"buzz"];
	expect(error).notTo.beNil();

	expect(error.domain).to.equal(GTGitErrorDomain);
	expect(error.code).to.equal(GIT_OK);
	expect(error.userInfo[NSLocalizedDescriptionKey]).to.equal(@"foo 1 bar buzz");
	expect(error.userInfo[NSLocalizedFailureReasonErrorKey]).to.beNil();
});

it(@"should create an error with a nil description and failure reason", ^{
	NSError *error = [NSError git_errorFor:GIT_OK description:nil failureReason:nil];
	expect(error).notTo.beNil();

	expect(error.domain).to.equal(GTGitErrorDomain);
	expect(error.code).to.equal(GIT_OK);
	expect(error.userInfo[NSLocalizedDescriptionKey]).to.beNil();
	expect(error.userInfo[NSLocalizedFailureReasonErrorKey]).to.beNil();
});

it(@"should create an error with a formatted failure reason", ^{
	NSError *error = [NSError git_errorFor:GIT_OK description:@"foobar" failureReason:@"foo %@ bar %@", @1, @"buzz"];
	expect(error).notTo.beNil();

	expect(error.domain).to.equal(GTGitErrorDomain);
	expect(error.code).to.equal(GIT_OK);
	expect(error.userInfo[NSLocalizedDescriptionKey]).to.equal(@"foobar");
	expect(error.userInfo[NSLocalizedFailureReasonErrorKey]).to.equal(@"foo 1 bar buzz");
});

afterEach(^{
	[self tearDown];
});

SpecEnd
