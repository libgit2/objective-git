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
		expect(mergeBase.sha).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
	});
});

describe(@"-OIDByCreatingTagNamed:target:tagger:message:error", ^{
	it(@"should create a new tag",^{
		NSError *error = nil;
		NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
		GTTag *tag = (GTTag *)[repo lookupObjectBySha:sha error:&error];

		GTOID *newOID = [repo OIDByCreatingTagNamed:@"a_new_tag" target:tag.target tagger:tag.tagger message:@"my tag\n" error:&error];
		expect(newOID).notTo.beNil();

		tag = (GTTag *)[repo lookupObjectByOid:newOID error:&error];
		expect(error).to.beNil();
		expect(tag).notTo.beNil();
		expect(newOID.SHA).to.equal(tag.sha);
		expect(tag.type).to.equal(@"tag");
		expect(tag.message).to.equal(@"my tag\n");
		expect(tag.name).to.equal(@"a_new_tag");
		expect(tag.target.sha).to.equal(@"5b5b025afb0b4c913b4c338a42934a3863bf3644");
		expect(tag.targetType).to.equal(@"commit");

		rm_loose(self.class, newOID.SHA);
		NSFileManager *m = [[NSFileManager alloc] init];
		NSURL *tagPath = [[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] URLByAppendingPathComponent:@"refs/tags/a_new_tag"];
		[m removeItemAtURL:tagPath error:&error];
	});

	it(@"should fail to create an already existing tag", ^{
		NSError *error = nil;
		NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
		GTTag *tag = (GTTag *)[repo lookupObjectBySha:sha error:&error];

		GTOID *oid = [repo OIDByCreatingTagNamed:tag.name target:tag.target tagger:tag.tagger message:@"new message" error:&error];
		expect(oid).to.beNil();
		expect(error).notTo.beNil();
	});
});

SpecEnd
