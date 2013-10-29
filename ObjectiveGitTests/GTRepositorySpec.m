//
//  GTRepositorySpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-04-29.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"
#import "GTRepository+Committing.h"

SpecBegin(GTRepository)

__block GTRepository *repository;
__block GTRepository * (^createRepository)(BOOL bare);

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo.beNil();

	createRepository = ^(BOOL bare) {
		NSURL *newRepoURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"unit_test"]];
		[NSFileManager.defaultManager removeItemAtURL:newRepoURL error:NULL];

		GTRepository *repository = [GTRepository initializeEmptyRepositoryAtFileURL:newRepoURL bare:bare error:NULL];
		expect(repository).notTo.beNil();
		expect(repository.gitDirectoryURL).notTo.beNil();
		return repository;
	};

});

describe(@"+repositoryWithURL:error:", ^{
	it(@"should fail to open non existent repos", ^{
		NSError *error = nil;
		GTRepository *badRepo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:@"fake/1235"] error:&error];

		expect(badRepo).to.beNil();
		expect(error).notTo.beNil();
	});
});

describe(@"+initializeEmptyRepositoryAtFileURL:bare:error:", ^{
	it(@"should initialize a repository with a working directory by default", ^{
		GTRepository *repository = createRepository(NO);
		expect(repository.bare).to.beFalsy();
		expect(repository.fileURL).notTo.beNil();
	});

	it(@"should initialize a bare repository", ^{
		GTRepository *repository = createRepository(YES);
		expect(repository.bare).to.beTruthy();
		expect(repository.fileURL).to.beNil();
	});

	it(@"should be empty", ^{
		GTRepository *repo = createRepository(NO);
		expect(repo.empty).to.beTruthy();
	});

	it(@"should not have a HEAD", ^{
		GTRepository *repo = createRepository(NO);
		expect(repo.isHEADUnborn).to.beTruthy();
	});
});

describe(@"+cloneFromURL:toWorkingDirectory:options:error:transferProgressBlock:checkoutProgressBlock:", ^{
	__block BOOL transferProgressCalled = NO;
	__block BOOL checkoutProgressCalled = NO;
	__block void (^transferProgressBlock)(const git_transfer_progress *);
	__block void (^checkoutProgressBlock)(NSString *, NSUInteger, NSUInteger);
	__block NSURL *originURL;
	__block NSURL *workdirURL;

	beforeEach(^{
		transferProgressCalled = NO;
		checkoutProgressCalled = NO;
		transferProgressBlock = ^(const git_transfer_progress *progress) { transferProgressCalled = YES; };
		checkoutProgressBlock = ^(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps) { checkoutProgressCalled = YES; };

		workdirURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"unit_test"]];

		[NSFileManager.defaultManager removeItemAtURL:workdirURL error:NULL];
	});

	describe(@"with local repositories", ^{
		beforeEach(^{
			originURL = self.bareFixtureRepository.gitDirectoryURL; //[NSURL URLWithString: @"https://github.com/libgit2/TestGitRepository"];
		});

		it(@"should clone existing repositories", ^{
			NSError *error;

			GTRepository *repo = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:nil error:&error transferProgressBlock:transferProgressBlock checkoutProgressBlock:checkoutProgressBlock];
			expect(repo).notTo.beNil();
			expect(error).to.beNil();
			expect(repo.bare).to.beFalsy();
			expect(transferProgressCalled).to.beTruthy();
			expect(checkoutProgressCalled).to.beTruthy();

			GTReference *head = [repo headReferenceWithError:&error];
			expect(error).to.beNil();
			expect(head.targetSHA).to.equal(@"36060c58702ed4c2a40832c51758d5344201d89a");
			expect(head.referenceType).to.equal(GTReferenceTypeOid);
		});

		it(@"should clone repositories (bare)", ^{
			NSDictionary *options = @{ GTRepositoryCloneOptionsBare: @YES };
			NSError *error;

			GTRepository *repo = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:options error:&error transferProgressBlock:transferProgressBlock checkoutProgressBlock:checkoutProgressBlock];
			expect(repo).notTo.beNil();
			expect(error).to.beNil();
			expect(repo.bare).to.beTruthy();
			expect(transferProgressCalled).to.beTruthy();
			expect(checkoutProgressCalled).to.beFalsy();

			GTReference *head = [repo headReferenceWithError:&error];
			expect(error).to.beNil();
			expect(head.targetSHA).to.equal(@"36060c58702ed4c2a40832c51758d5344201d89a");
			expect(head.referenceType).to.equal(GTReferenceTypeOid);
		});
	});
});

describe(@"-headReferenceWithError:", ^{
	it(@"should return HEAD for a born repo", ^{
		expect(self.bareFixtureRepository.isHEADUnborn).to.beFalsy();

		NSError *error = nil;
		GTReference *head = [self.bareFixtureRepository headReferenceWithError:&error];
		expect(error).to.beNil();
		expect(head.targetSHA).to.equal(@"36060c58702ed4c2a40832c51758d5344201d89a");
		expect(head.referenceType).to.equal(GTReferenceTypeOid);
	});

	it(@"should fail to return HEAD for an unborn repo", ^{
		GTRepository *repo = createRepository(NO);
		expect(repo.isHEADUnborn).to.beTruthy();

		NSError *error = nil;
		GTReference *head = [repo headReferenceWithError:&error];
		expect(error).notTo.beNil();
		expect(head).to.beNil();
	});
});

describe(@"-resetToCommit:withResetType:error", ^{
	it(@"should move HEAD", ^{
		NSError *error = nil;
		GTRepository *aRepo = self.bareFixtureRepository;
		GTReference *originalHead = [aRepo headReferenceWithError:NULL];
		NSString *resetTargetSha = @"8496071c1b46c854b31185ea97743be6a8774479";

		GTCommit *commit = [aRepo lookupObjectBySHA:resetTargetSha error:NULL];

		BOOL success = [aRepo resetToCommit:commit withResetType:GTRepositoryResetTypeSoft error:&error];
		expect(success).to.beTruthy();
		expect(error).to.beNil();

		GTReference *head = [aRepo headReferenceWithError:&error];
		expect(head.targetSHA).to.equal(resetTargetSha);

		GTCommit *originalHeadCommit = [aRepo lookupObjectBySHA:originalHead.targetSHA error:NULL];
		success = [aRepo resetToCommit:originalHeadCommit withResetType:GTRepositoryResetTypeSoft error:&error];
		expect(success).to.beTruthy();
		expect(error).to.beNil();

		head = [aRepo headReferenceWithError:&error];
		expect(head.unresolvedTarget).to.equal(originalHead.unresolvedTarget);
	});
});

describe(@"-lookupObjectByRefspec:error:", ^{
	__block void (^expectSHAForRefspec)(NSString *SHA, NSString *refspec);

	beforeEach(^{
		expectSHAForRefspec = ^(NSString *SHA, NSString *refspec) {
			NSError *error = nil;
			GTObject *obj = [self.bareFixtureRepository lookupObjectByRefspec:refspec error:&error];

			if (SHA != nil) {
				expect(error).to.beNil();
				expect(obj).notTo.beNil();
				expect(obj.SHA).to.equal(SHA);
			} else {
				expect(error).notTo.beNil();
				expect(obj).to.beNil();
			}
		};
	});

	it(@"should return objects given a valid refspec", ^{
		expectSHAForRefspec(@"36060c58702ed4c2a40832c51758d5344201d89a", @"master");
		expectSHAForRefspec(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", @"master~");
		expectSHAForRefspec(@"8496071c1b46c854b31185ea97743be6a8774479", @"master@{2}");
		expectSHAForRefspec(@"0c37a5391bbff43c37f0d0371823a5509eed5b1d", @"v1.0");
	});

	it(@"should return nil for an invalid refspec", ^{
		expectSHAForRefspec(nil, @"master^2");
		expectSHAForRefspec(nil, @"");
	});

	it(@"should still work with a NULL error", ^{
		GTObject *obj = [self.bareFixtureRepository lookupObjectByRefspec:@"master" error:nil];
		expect(obj.SHA).to.equal(@"36060c58702ed4c2a40832c51758d5344201d89a");
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
		GTRepository *repo = self.bareFixtureRepository;
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
		expect(tag.targetType).to.equal(GTObjectTypeCommit);
	});

	it(@"should fail to create an already existing tag", ^{
		NSError *error = nil;
		NSString *SHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		GTRepository *repo = self.bareFixtureRepository;
		GTTag *tag = (GTTag *)[repo lookupObjectBySHA:SHA error:&error];

		GTOID *OID = [repo OIDByCreatingTagNamed:tag.name target:tag.target tagger:tag.tagger message:@"new message" error:&error];
		expect(OID).to.beNil();
		expect(error).notTo.beNil();
	});
});

describe(@"-checkout:strategy:error:progressBlock:", ^{
	it(@"should allow references", ^{
		NSError *error = nil;
		GTReference *ref = [GTReference referenceByLookingUpReferencedNamed:@"refs/heads/other-branch" inRepository:repository error:&error];
		expect(ref).to.beTruthy();
		expect(error.localizedDescription).to.beNil();
		BOOL result = [repository checkoutReference:ref strategy:GTCheckoutStrategyAllowConflicts error:&error progressBlock:nil];
		expect(result).to.beTruthy();
		expect(error.localizedDescription).to.beNil();
	});
	
	it(@"should allow commits", ^{
		NSError *error = nil;
		GTCommit *commit = [repository lookupObjectBySHA:@"1d69f3c0aeaf0d62e25591987b93b8ffc53abd77" objectType:GTObjectTypeCommit error:&error];
		expect(commit).to.beTruthy();
		expect(error.localizedDescription).to.beNil();
		BOOL result = [repository checkoutCommit:commit strategy:GTCheckoutStrategyAllowConflicts error:&error progressBlock:nil];
		expect(result).to.beTruthy();
		expect(error.localizedDescription).to.beNil();
	});
});

SpecEnd
