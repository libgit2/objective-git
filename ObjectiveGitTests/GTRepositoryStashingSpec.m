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
	repository = self.testAppFixtureRepository;
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

it(@"should enumerate stashes", ^{
	const int stashCount = 3;
	NSMutableArray *stashCommits = [NSMutableArray arrayWithCapacity:stashCount];

	for (int i = stashCount; i >= 0; i--) {
		NSString *filename = [NSString stringWithFormat:@"new-test-file-%i", i];
		expect([@"foobar" writeToURL:[repository.fileURL URLByAppendingPathComponent:filename] atomically:YES encoding:NSUTF8StringEncoding error:NULL]).to.beTruthy();

		NSString *message = [NSString stringWithFormat:@"stash %i", i];

		NSError *error = nil;
		GTCommit *stash = [repository stashChangesWithMessage:message flags:GTRepositoryStashFlagIncludeUntracked error:&error];
		expect(stash).notTo.beNil();
		expect(error).to.beNil();

		[stashCommits insertObject:stash atIndex:0];
	}

	__block NSUInteger lastIndex = 0;
	[repository enumerateStashesUsingBlock:^(NSUInteger i, NSString *message, GTOID *oid, BOOL *stop) {
		lastIndex = i;

		NSString *expectedMessage = [NSString stringWithFormat:@"On master: stash %lu", (unsigned long)i];
		expect(oid).to.equal([stashCommits[i] OID]);
		expect(message).to.equal(expectedMessage);

		if (i == 2) *stop = YES;
	}];

	expect(lastIndex).to.equal(2);
});

afterEach(^{
	[self tearDown];
});

SpecEnd
