//
//  GTRepositorySpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-04-29.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

SpecBegin(GTRepository)

__block GTRepository *repository;

beforeEach(^{
	repository = [self fixtureRepositoryNamed:@"Test_App"];
	expect(repository).notTo.beNil();
});

describe(@"-initializeEmptyRepositoryAtURL:bare:error:", ^{
	it(@"should initialize a repository with a working directory by default", ^{
		__block NSError *error = nil;
		NSURL *newRepoURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"unit_test"]];
		[[NSFileManager defaultManager] removeItemAtURL:newRepoURL error:NULL];

		expect([GTRepository initializeEmptyRepositoryAtURL:newRepoURL error:&error]).to.beTruthy();
		GTRepository *newRepo = [GTRepository repositoryWithURL:newRepoURL error:&error];
		expect(newRepo).toNot.beNil();
		expect(error).to.beNil();
		expect(newRepo.fileURL).toNot.beNil(); // working directory
		expect(newRepo.bare).to.beFalsy();
	});

	it(@"should initialize a bare repository", ^{
		__block NSError *error = nil;
		NSURL *newRepoURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"unit_test"]];
		[[NSFileManager defaultManager] removeItemAtURL:newRepoURL error:NULL];

		expect([GTRepository initializeEmptyRepositoryAtURL:newRepoURL bare:YES error:&error]).to.beTruthy();
		GTRepository *newRepo = [GTRepository repositoryWithURL:newRepoURL error:&error];
		expect(newRepo).toNot.beNil();
		expect(error).to.beNil();
		expect(newRepo.fileURL).to.beNil(); // working directory
		expect(newRepo.bare).to.beTruthy();
	});
});

describe(@"-preparedMessage", ^{
	it(@"should return nil by default", ^{
		__block NSError *error = nil;
		expect([repository preparedMessageWithError:&error]).to.beNil();
		expect(error).to.beNil();
	});

	it(@"should return the contents of MERGE_MSG", ^{
		NSString *message = @"Commit summary\n\ndescription";
		expect([message writeToURL:[repository.gitDirectoryURL URLByAppendingPathComponent:@"MERGE_MSG"] atomically:YES encoding:NSUTF8StringEncoding error:NULL]).to.beTruthy();

		__block NSError *error = nil;
		expect([repository preparedMessageWithError:&error]).to.equal(message);
		expect(error).to.beNil();
	});
});

describe(@"-mergeBaseBetweenFirstOID:secondOID:error:", ^{
	it(@"should find the merge base between two branches", ^{
		NSError *error = nil;
		GTBranch *masterBranch = [[GTBranch alloc] initWithName:@"refs/heads/master" repository:repository error:&error];
		expect(masterBranch).notTo.beNil();
		expect(error).to.beNil();

		GTBranch *otherBranch = [[GTBranch alloc] initWithName:@"refs/heads/other-branch" repository:repository error:&error];
		expect(otherBranch).notTo.beNil();
		expect(error).to.beNil();

		GTCommit *mergeBase = [repository mergeBaseBetweenFirstOID:masterBranch.reference.OID secondOID:otherBranch.reference.OID error:&error];
		expect(mergeBase).notTo.beNil();
		expect(mergeBase.SHA).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
	});
});

describe(@"-allTagsWithError:", ^{
	it(@"should return all tags", ^{
		NSError *error = nil;
		NSArray *tags = [repository allTagsWithError:&error];
		expect(tags).notTo.beNil();
		expect(tags.count).to.equal(0);
	});
});

describe(@"-stashChangesWithMessage:flags:error:", ^{
	it(@"should fail if there's nothing to stash (with default options)", ^{
		NSError *error = nil;
		GTCommit *stash = [repository stashChangesWithMessage:nil flags:GTRepositoryStashFlagDefault error:&error];
		expect(stash).to.beNil();
		expect(error).notTo.beNil();
		expect(error.code).to.equal(GIT_ENOTFOUND);
	});
});

SpecEnd
