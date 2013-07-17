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

describe(@"-OIDByCreatingTagNamed:target:tagger:message:error", ^{
	it(@"should create a new tag",^{
		NSError *error = nil;
		NSString *SHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
		GTTag *tag = (GTTag *)[repo lookupObjectBySHA:SHA error:&error];

		GTOID *newOID = [repo OIDByCreatingTagNamed:@"a_new_tag" target:tag.target tagger:tag.tagger message:@"my tag\n" error:&error];
		expect(newOID).notTo.beNil();

		tag = (GTTag *)[repo lookupObjectByOID:newOID error:&error];
		expect(error).to.beNil();
		expect(tag).notTo.beNil();
		expect(newOID.SHA).to.equal(tag.SHA);
		expect(tag.type).to.equal(@"tag");
		expect(tag.message).to.equal(@"my tag\n");
		expect(tag.name).to.equal(@"a_new_tag");
		expect(tag.target.SHA).to.equal(@"5b5b025afb0b4c913b4c338a42934a3863bf3644");
		expect(tag.targetType).to.equal(@"commit");

		rm_loose(self.class, newOID.SHA);
		NSFileManager *m = [[NSFileManager alloc] init];
		NSURL *tagPath = [[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] URLByAppendingPathComponent:@"refs/tags/a_new_tag"];
		[m removeItemAtURL:tagPath error:&error];
	});

	it(@"should fail to create an already existing tag", ^{
		NSError *error = nil;
		NSString *SHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
		GTTag *tag = (GTTag *)[repo lookupObjectBySHA:SHA error:&error];

		GTOID *OID = [repo OIDByCreatingTagNamed:tag.name target:tag.target tagger:tag.tagger message:@"new message" error:&error];
		expect(OID).to.beNil();
		expect(error).notTo.beNil();
	});
});

SpecEnd
