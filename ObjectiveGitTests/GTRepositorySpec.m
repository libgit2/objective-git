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

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo.beNil();
});

describe(@"+initializeEmptyRepositoryAtFileURL:bare:error:", ^{
	it(@"should initialize a repository with a working directory by default", ^{
		NSURL *newRepoURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"init-repo"];

		GTRepository *repository = [GTRepository initializeEmptyRepositoryAtFileURL:newRepoURL bare:NO error:NULL];
		expect(repository).notTo.beNil();
		expect(repository.gitDirectoryURL).notTo.beNil();
		expect(repository.bare).to.beFalsy();
	});

	it(@"should initialize a bare repository", ^{
		NSURL *newRepoURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"init-repo.git"];

		GTRepository *repository = [GTRepository initializeEmptyRepositoryAtFileURL:newRepoURL bare:YES error:NULL];
		expect(repository).notTo.beNil();
		expect(repository.gitDirectoryURL).notTo.beNil();
		return repository;
		expect(repository.bare).to.beTruthy();
	});
});

describe(@"+repositoryWithURL:error:", ^{
	it(@"should fail to initialize non-existent repos", ^{
		NSError *error = nil;
		GTRepository *badRepo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:@"fake/1235"] error:&error];
		expect(badRepo).to.beNil();
		expect(error).notTo.beNil();
		expect(error.domain).to.equal(GTGitErrorDomain);
		expect(error.code).to.equal(GIT_ENOTFOUND);
	});
});

describe(@"+cloneFromURL:toWorkingDirectory:options:error:transferProgressBlock:checkoutProgressBlock:", ^{
	__block BOOL transferProgressCalled = NO;
	__block BOOL checkoutProgressCalled = NO;
	__block void (^transferProgressBlock)(const git_transfer_progress *);
	__block void (^checkoutProgressBlock)(NSString *, NSUInteger, NSUInteger);
	__block NSURL *originURL;
	__block NSURL *workdirURL;

	// TODO: Make real remote tests using a repo somewhere

	beforeEach(^{
		transferProgressCalled = NO;
		checkoutProgressCalled = NO;
		transferProgressBlock = ^(const git_transfer_progress *progress) {
            transferProgressCalled = YES;
        };
		checkoutProgressBlock = ^(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps) {
            checkoutProgressCalled = YES;
        };

		workdirURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"temp-repo"];
	});

	describe(@"with local repositories", ^{
		beforeEach(^{
			originURL = self.bareFixtureRepository.gitDirectoryURL;
		});

		it(@"should handle normal clones", ^{
			NSError *error = nil;
			repository = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:nil error:&error transferProgressBlock:transferProgressBlock checkoutProgressBlock:checkoutProgressBlock];
			expect(repository).notTo.beNil();
			expect(error).to.beNil();
			expect(transferProgressCalled).to.beTruthy();
			expect(checkoutProgressCalled).to.beTruthy();

			expect(repository.isBare).to.beFalsy();

			GTReference *head = [repository headReferenceWithError:&error];
			expect(head).notTo.beNil();
			expect(error).to.beNil();
			expect(head.targetSHA).to.equal(@"36060c58702ed4c2a40832c51758d5344201d89a");
			expect(head.referenceType).to.equal(GTReferenceTypeOid);
		});

		it(@"should handle bare clones", ^{
			NSError *error = nil;
			NSDictionary *options = @{ GTRepositoryCloneOptionsBare: @YES };
			repository = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:options error:&error transferProgressBlock:transferProgressBlock checkoutProgressBlock:checkoutProgressBlock];
			expect(repository).notTo.beNil();
			expect(error).to.beNil();
			expect(transferProgressCalled).to.beTruthy();
			expect(checkoutProgressCalled).to.beFalsy();

			expect(repository.isBare).to.beTruthy();

			GTReference *head = [repository headReferenceWithError:&error];
			expect(head).notTo.beNil();
			expect(error).to.beNil();
			expect(head.targetSHA).to.equal(@"36060c58702ed4c2a40832c51758d5344201d89a");
			expect(head.referenceType).to.equal(GTReferenceTypeOid);
		});

		it(@"should have set a valid remote URL", ^{
			NSError *error = nil;
			GTRepository *repo = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:nil error:&error transferProgressBlock:transferProgressBlock checkoutProgressBlock:checkoutProgressBlock];
			expect(repo).notTo.beNil();
			expect(error).to.beNil();

			// FIXME: Move that to a method in GTRepository ?
			// Or use the new initializers in GTRemote that are waiting in #224
			git_remote *remote;
			git_remote_load(&remote, repo.git_repository, "origin");
			GTRemote *originRemote = [[GTRemote alloc] initWithGitRemote:remote];
			expect(originRemote.URLString).to.equal(originURL.path);
		});
	});
});

describe(@"-headReferenceWithError:", ^{
	it(@"should allow HEAD to be looked up", ^{
		NSError *error = nil;
		GTReference *head = [self.bareFixtureRepository headReferenceWithError:&error];
		expect(head).notTo.beNil();
		expect(error).to.beNil();
		expect(head.targetSHA).to.equal(@"36060c58702ed4c2a40832c51758d5344201d89a");
		expect(head.referenceType).to.equal(GTReferenceTypeOid);
	});

	it(@"should fail to return HEAD for an unborn repo", ^{
		GTRepository *repo = self.blankFixtureRepository;
		expect(repo.isHEADUnborn).to.beTruthy();

		NSError *error = nil;
		GTReference *head = [repo headReferenceWithError:&error];
		expect(head).to.beNil();
		expect(error).notTo.beNil();
		expect(error.domain).to.equal(GTGitErrorDomain);
        expect(error.code).to.equal(GIT_EUNBORNBRANCH);
	});
});

describe(@"-isEmpty", ^{
	it(@"should return NO for a non-empty repository", ^{
		expect(repository.isEmpty).to.beFalsy();
	});

	it(@"should return YES for a new repository", ^{
		NSError *error = nil;
		NSURL *fileURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"newrepo"];
		GTRepository *newRepo = [GTRepository initializeEmptyRepositoryAtFileURL:fileURL error:&error];
		expect(newRepo.isEmpty).to.beTruthy();
		[NSFileManager.defaultManager removeItemAtURL:fileURL error:NULL];
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
		GTBranch *masterBranch = [GTBranch branchByLookingUpBranchNamed:@"master" inRepository:repository error:&error];
		expect(masterBranch).notTo.beNil();
		expect(error).to.beNil();

		GTBranch *otherBranch = [GTBranch branchByLookingUpBranchNamed:@"other-branch" inRepository:repository error:&error];
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

describe(@"-currentBranchWithError:", ^{
	it(@"should return the current branch", ^{
		NSError *error = nil;
		GTBranch *currentBranch = [repository currentBranchWithError:&error];
		expect(currentBranch).notTo.beNil();
		expect(error).to.beNil();
		expect(currentBranch.reference.name).to.equal(@"refs/heads/master");
	});
});

describe(@"-localBranchesWithError:", ^{
	it(@"should return the local branches", ^{
		NSError *error = nil;
		NSArray *branches = [repository localBranchesWithError:&error];
		expect(branches).notTo.beNil();
		expect(error).to.beNil();
		expect(branches.count).to.equal(13);
	});
});

describe(@"-remoteBranchesWithError:", ^{
	it(@"should return remote branches", ^{
		NSError *error = nil;
		NSArray *branches = [repository remoteBranchesWithError:&error];
		expect(branches).notTo.beNil();
		expect(error).to.beNil();
		expect(branches.count).to.equal(1);
		GTBranch *remoteBranch = branches[0];
		expect(remoteBranch.reference.name).to.equal(@"refs/remotes/origin/master");
	});
});

describe(@"-referenceNamesWithError:", ^{
	it(@"should return reference names", ^{
		NSError *error = nil;
		NSArray *refs = [self.bareFixtureRepository referenceNamesWithError:&error];
		expect(refs).notTo.beNil();
		expect(error).to.beNil();

		expect(refs.count).to.equal(4);
		NSArray *expectedRefs = @[ @"refs/heads/master", @"refs/tags/v0.9", @"refs/tags/v1.0", @"refs/heads/packed" ];
		expect(refs).to.equal(expectedRefs);
	});
});

describe(@"-checkout:strategy:error:progressBlock:", ^{
	it(@"should allow references", ^{
		NSError *error = nil;
		GTReference *ref = [GTReference referenceByLookingUpReferenceNamed:@"refs/heads/other-branch" inRepository:repository error:&error];
		expect(ref).to.beTruthy();
		expect(error.localizedDescription).to.beNil();
		BOOL result = [repository checkoutReference:ref strategy:GTCheckoutStrategyAllowConflicts error:&error progressBlock:nil];
		expect(result).to.beTruthy();
		expect(error.localizedDescription).to.beNil();
	});
	
	it(@"should allow commits", ^{
		NSError *error = nil;
		GTCommit *commit = [GTCommit lookupWithSHA:@"1d69f3c0aeaf0d62e25591987b93b8ffc53abd77" inRepository:repository error:&error];
		expect(commit).to.beTruthy();
		expect(error.localizedDescription).to.beNil();
		BOOL result = [repository checkoutCommit:commit strategy:GTCheckoutStrategyAllowConflicts error:&error progressBlock:nil];
		expect(result).to.beTruthy();
		expect(error.localizedDescription).to.beNil();
	});
});

describe(@"-resetToCommit:withResetType:error:", ^{
	beforeEach(^{
		repository = self.bareFixtureRepository;
	});

	it(@"should move HEAD when used", ^{
		NSError *error = nil;
		GTReference *originalHead = [repository headReferenceWithError:NULL];
		NSString *resetTargetSHA = @"8496071c1b46c854b31185ea97743be6a8774479";

		GTCommit *commit = [GTCommit lookupWithSHA:resetTargetSHA inRepository:repository error:NULL];
		expect(commit).notTo.beNil();
		GTCommit *originalHeadCommit = [GTCommit lookupWithSHA:originalHead.targetSHA inRepository:repository error:NULL];
		expect(originalHeadCommit).notTo.beNil();

		BOOL success = [repository resetToCommit:commit withResetType:GTRepositoryResetTypeSoft error:&error];
		expect(success).to.beTruthy();
		expect(error).to.beNil();

		GTReference *head = [repository headReferenceWithError:&error];
		expect(head).notTo.beNil();
		expect(head.targetSHA).to.equal(resetTargetSHA);

		success = [repository resetToCommit:originalHeadCommit withResetType:GTRepositoryResetTypeSoft error:&error];
		expect(success).to.beTruthy();
		expect(error).to.beNil();

		head = [repository headReferenceWithError:&error];
		expect(head.targetSHA).to.equal(originalHead.targetSHA);
	});
});

describe(@"-lookupObjectByRevspec:error:", ^{
	void (^expectSHAForRevspec)(NSString *SHA, NSString *revspec) = ^(NSString *SHA, NSString *revspec) {
		NSError *error = nil;
		GTObject *obj = [repository lookupObjectByRevspec:revspec error:&error];

		if (SHA != nil) {
			expect(error).to.beNil();
			expect(obj).notTo.beNil();
			expect(obj.SHA).to.equal(SHA);
		} else {
			expect(error).notTo.beNil();
			expect(obj).to.beNil();
		}
	};;

	beforeEach(^{
		repository = self.bareFixtureRepository;
	});

	it(@"should parse various revspecs", ^{
		expectSHAForRevspec(@"36060c58702ed4c2a40832c51758d5344201d89a", @"master");
		expectSHAForRevspec(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", @"master~");
		expectSHAForRevspec(@"8496071c1b46c854b31185ea97743be6a8774479", @"master@{2}");
		expectSHAForRevspec(nil, @"master^2");
		expectSHAForRevspec(nil, @"");
		expectSHAForRevspec(@"0c37a5391bbff43c37f0d0371823a5509eed5b1d", @"v1.0");
	});
});

SpecEnd
