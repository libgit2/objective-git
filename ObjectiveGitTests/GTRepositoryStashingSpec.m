//
//  GTRepositoryStashingSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-09-27.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Stashing.h"

SpecBegin(GTRepositoryStashing)

__block GTRepository *repository;

beforeEach(^{
	repository = [self fixtureRepositoryNamed:@"Test_App"];
	expect(repository).notTo.beNil();
});

it(@"should fail to create a stash if there's nothing to stash", ^{
	NSError *error = nil;
	GTCommit *stash = [repository stashChangesWithMessage:nil flags:GTRepositoryStashFlagDefault error:&error];
	expect(stash).to.beNil();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(GTGitErrorDomain);
	expect(error.code).to.equal(GIT_ENOTFOUND);
});

it(@"should create a stash with modified file content", ^{
	NSURL *fileURL = [repository.fileURL URLByAppendingPathComponent:@"README.md"];
	NSString *newContent = @"foobar";

	NSString *oldContent = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
	expect(oldContent).notTo.equal(newContent);

	expect([newContent writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:NULL]).to.beTruthy();
	expect([NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL]).to.equal(newContent);

	NSError *error = nil;
	GTCommit *stash = [repository stashChangesWithMessage:nil flags:GTRepositoryStashFlagDefault error:&error];
	expect(stash).notTo.beNil();
	expect(error).to.beNil();

	expect([NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL]).to.equal(oldContent);
});

it(@"should create a stash with uncommitted changes", ^{
	NSURL *fileURL = [repository.fileURL URLByAppendingPathComponent:@"README.md"];
	NSString *newContent = @"foobar";

	NSString *oldContent = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
	expect(oldContent).notTo.equal(newContent);

	expect([newContent writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:NULL]).to.beTruthy();
	expect([NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL]).to.equal(newContent);

	NSError *error = nil;
	GTCommit *stash = [repository stashChangesWithMessage:nil flags:GTRepositoryStashFlagDefault error:&error];
	expect(stash).notTo.beNil();
	expect(error).to.beNil();

	expect([NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL]).to.equal(oldContent);
});

it(@"should fail to create a stash with an untracked file using default options", ^{
	expect([@"foobar" writeToURL:[repository.fileURL URLByAppendingPathComponent:@"new-test-file"] atomically:YES encoding:NSUTF8StringEncoding error:NULL]).to.beTruthy();

	NSError *error = nil;
	GTCommit *stash = [repository stashChangesWithMessage:nil flags:GTRepositoryStashFlagDefault error:&error];
	expect(stash).to.beNil();

	expect(error).notTo.beNil();
	expect(error.domain).to.equal(GTGitErrorDomain);
	expect(error.code).to.equal(GIT_ENOTFOUND);
});

it(@"should stash an untracked file when enabled", ^{
	expect([@"foobar" writeToURL:[repository.fileURL URLByAppendingPathComponent:@"new-test-file"] atomically:YES encoding:NSUTF8StringEncoding error:NULL]).to.beTruthy();

	NSError *error = nil;
	GTCommit *stash = [repository stashChangesWithMessage:nil flags:GTRepositoryStashFlagIncludeUntracked error:&error];
	expect(stash).notTo.beNil();
	expect(error).to.beNil();
});

SpecEnd
