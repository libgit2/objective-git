//
//  GTBranchSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/22/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTBranch.h"

SpecBegin(GTBranch)

__block GTRepository *repository;
__block GTBranch *masterBranch;
__block GTBranch *trackingBranch;

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo.beNil();

	NSError *error = nil;
	masterBranch = [repository currentBranchWithError:&error];
	expect(masterBranch).notTo.beNil();
	expect(error).to.beNil();

	trackingBranch = [masterBranch trackingBranchWithError:&error];
	expect(trackingBranch).notTo.equal(masterBranch);
	expect(error).to.beNil();
});

describe(@"branch initialization", ^{
	describe(@"+branchByLookingUpBranchNamed:type:inRepository:error:", ^{
		it(@"works for local branches", ^{
			NSError *error = nil;
			GTBranch *branch = [GTBranch branchByLookingUpBranchNamed:@"master" type:GTBranchTypeLocal inRepository:repository error:&error];
			expect(branch).notTo.beNil();
			expect(error).to.beNil();
			expect(branch.branchType).to.equal(GTBranchTypeLocal);
		});

		it(@"works for remote branches", ^{
			NSError *error = nil;
			GTBranch *branch = [GTBranch branchByLookingUpBranchNamed:@"origin/master" type:GTBranchTypeRemote inRepository:repository error:&error];
			expect(branch).notTo.beNil();
			expect(error).to.beNil();
			expect(branch.branchType).to.equal(GTBranchTypeRemote);
		});

		it(@"fails for non-existing branches", ^{
			NSError *error = nil;
			GTBranch *branch = [GTBranch branchByLookingUpBranchNamed:@"plonk" type:GTBranchTypeRemote inRepository:repository error:&error];
			expect(branch).to.beNil();
			expect(error.domain).to.equal(GTGitErrorDomain);
			expect(error.code).to.equal(GIT_ENOTFOUND);
		});

		it(@"finds local branches before remote ones in an 'any' lookup", ^{
			NSError *error = nil;
			GTReference *ref = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/origin/master" fromReferenceTarget:@"refs/heads/master" inRepository:repository error:NULL];
			expect(ref).notTo.beNil();

			GTBranch *duplicateBranch = [GTBranch branchWithReference:ref];
			expect(duplicateBranch).notTo.beNil();
			expect(duplicateBranch.branchType).to.equal(GTBranchTypeLocal);

			GTBranch *remoteBranch = [GTBranch branchByLookingUpBranchNamed:@"origin/master" type:GTBranchTypeRemote inRepository:repository error:NULL];
			expect(remoteBranch).notTo.beNil();
			expect(remoteBranch.branchType).to.equal(GTBranchTypeRemote);

			GTBranch *branch = [GTBranch branchByLookingUpBranchNamed:@"origin/master" type:GTBranchTypeAny inRepository:repository error:&error];
			expect(branch).notTo.beNil();
			expect(error).to.beNil();
			expect(branch.branchType).to.equal(GTBranchTypeLocal);
			expect(branch).to.equal(duplicateBranch);
		});

		it(@"find remote branches if there's no ambiguity in an 'any' lookup", ^{
			NSError *error = nil;

			GTBranch *branch = [GTBranch branchByLookingUpBranchNamed:@"origin/master" type:GTBranchTypeAny inRepository:repository error:&error];
			expect(branch).notTo.beNil();
			expect(error).to.beNil();
			expect(branch.branchType).to.equal(GTBranchTypeRemote);
		});
	});

	describe(@"+branchByCreatingBranchNamed:target:force:inRepository:error:", ^{
		it(@"works with a non-conflicting name", ^{
			NSError *error = nil;
			GTCommit *targetCommit = [masterBranch targetCommitAndReturnError:NULL];
			GTBranch *branch = [GTBranch branchByCreatingBranchNamed:@"my-branch" target:targetCommit force:NO inRepository:repository error:&error];
			expect(branch).notTo.beNil();
			expect(error).to.beNil();
			expect(branch.branchType).to.equal(GTBranchTypeLocal);
		});

		it(@"fails with an already existing name", ^{
			NSError *error = nil;
			GTCommit *targetCommit = [masterBranch targetCommitAndReturnError:NULL];
			GTBranch *branch = [GTBranch branchByCreatingBranchNamed:@"1-and_more" target:targetCommit force:NO inRepository:repository error:&error];
			expect(branch).to.beNil();
			expect(error.domain).to.equal(GTGitErrorDomain);
			expect(error.code).to.equal(GIT_EEXISTS);
		});

		it(@"delete the offending branch if creation is forced", ^{
			NSError *error = nil;
			GTCommit *targetCommit = [masterBranch targetCommitAndReturnError:NULL];
			GTBranch *branch = [GTBranch branchByCreatingBranchNamed:@"1-and_more" target:targetCommit force:YES inRepository:repository error:&error];
			expect(branch).notTo.beNil();
			expect(error).to.beNil();
		});
	});

	describe(@"+branchWithReferenceNamed:inRepository:error:", ^{
		it(@"works for existing local references", ^{
			NSError *error = nil;
			GTBranch *branch = [GTBranch branchWithReferenceNamed:@"refs/heads/1-and_more" inRepository:repository error:&error];
			expect(branch).notTo.beNil();
			expect(error).to.beNil();
		});

		it(@"works for existing remote references", ^{
			NSError *error = nil;
			GTBranch *branch = [GTBranch branchWithReferenceNamed:@"refs/remotes/origin/master" inRepository:repository error:&error];
			expect(branch).notTo.beNil();
			expect(error).to.beNil();
		});

		it(@"fails for non existent references", ^{
			NSError *error = nil;
			GTBranch *branch = [GTBranch branchWithReferenceNamed:@"refs/heads/nowhere" inRepository:repository error:&error];
			expect(branch).to.beNil();
			expect(error.domain).to.equal(GTGitErrorDomain);
			expect(error.code).to.equal(GIT_ENOTFOUND);
		});
	});
});

describe(@"basic properties", ^{
	describe(@"local branches", ^{
		it(@"should be GTBranchTypeLocal for a local branch", ^{
			expect(masterBranch.branchType).to.equal(GTBranchTypeLocal);
		});

		it(@"should use just the branch name in their name", ^{
			expect(masterBranch.name).to.equal(@"master");
		});

		it(@"should use just the branch name in their short name", ^{
			expect(masterBranch.shortName).to.equal(@"master");
		});

		it(@"should return nil for their remote name", ^{
			expect(masterBranch.remoteName).to.beNil();
		});
	});

	describe(@"remote branches", ^{
		it(@"should have a GTBranchTypeLocal branch type", ^{
			expect(trackingBranch.branchType).to.equal(GTBranchTypeRemote);
		});

		it(@"should include the remote name in their name", ^{
			expect(trackingBranch.name).to.equal(@"origin/master");
		});

		it(@"should not include the remote name in their short name", ^{
			expect(trackingBranch.shortName).to.equal(@"master");
		});

		it(@"should return the remote name for their remote name", ^{
			expect(trackingBranch.remoteName).to.equal(@"origin");
		});
	});
});

describe(@"-calculateAhead:behind:relativeTo:error:", ^{
	it(@"should calculate ahead/behind relative to the tracking branch", ^{
		size_t ahead = 0;
		size_t behind = 0;
		[masterBranch calculateAhead:&ahead behind:&behind relativeTo:trackingBranch error:NULL];
		expect(ahead).to.equal(9);
		expect(behind).to.equal(0);
	});

	it(@"should calculate ahead/behind relative to the local branch", ^{
		size_t ahead = 0;
		size_t behind = 0;
		[trackingBranch calculateAhead:&ahead behind:&behind relativeTo:masterBranch error:NULL];
		expect(ahead).to.equal(0);
		expect(behind).to.equal(9);
	});
});

describe(@"-uniqueCommitsRelativeToBranch:error:", ^{
	it(@"should return unique commits relative to the tracking branch", ^{
		NSError *error = nil;
		NSArray *commits = [masterBranch uniqueCommitsRelativeToBranch:trackingBranch error:&error];
		expect(commits).notTo.beNil();
		expect(error).to.beNil();

		NSMutableArray *SHAs = [NSMutableArray array];
		for (GTCommit *commit in commits) {
			[SHAs addObject:commit.SHA];
		}

		NSArray *expectedSHAs = @[
			@"a4bca6b67a5483169963572ee3da563da33712f7",
			@"6b0c1c8b8816416089c534e474f4c692a76ac14f",
			@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0",
			@"82dc47f6ba3beecab33080a1136d8913098e1801",
			@"93f5b550149f9f4c702c9de9a8b0a8a357f0c41c",
			@"1d69f3c0aeaf0d62e25591987b93b8ffc53abd77",
			@"3c273013b9b7af154f7e30f785a8affda37f85e1",
			@"6317779b4731d9c837dcc6972b964bdf4211eeef",
			@"9f90c6e24629fae3ef51101bb6448342b44098ef",
		];

		expect(SHAs).to.equal(expectedSHAs);
	});

	it(@"should return no unique commits relative to the local branch", ^{
		NSError *error = nil;
		NSArray *commits = [trackingBranch uniqueCommitsRelativeToBranch:masterBranch error:&error];
		expect(commits).to.equal(@[]);
		expect(error).to.beNil();
	});
});

describe(@"-reloadedBranchWithError:", ^{
	it(@"should reload the branch from disk", ^{
		static NSString * const originalSHA = @"a4bca6b67a5483169963572ee3da563da33712f7";
		static NSString * const updatedSHA = @"6b0c1c8b8816416089c534e474f4c692a76ac14f";
		expect([masterBranch targetCommitAndReturnError:NULL].SHA).to.equal(originalSHA);
		[masterBranch.reference referenceByUpdatingTarget:updatedSHA error:NULL];

		GTBranch *reloadedBranch = [masterBranch reloadedBranchWithError:NULL];
		expect(reloadedBranch).notTo.beNil();
		expect([reloadedBranch targetCommitAndReturnError:NULL].SHA).to.equal(updatedSHA);
		expect([masterBranch targetCommitAndReturnError:NULL].SHA).to.equal(originalSHA);
	});
});

describe(@"-numberOfCommitsWithError:", ^{
	it(@"should return the count of commits in the branch", ^{
		NSError *error = nil;
		NSUInteger commitCount = [masterBranch numberOfCommitsWithError:&error];
		expect(commitCount).to.equal(164);
		expect(error).to.beNil();
	});
});

describe(@"-trackingBranchWithError:success:", ^{
	it(@"should return the tracking branch for a local branch that tracks a remote branch", ^{
		NSError *error = nil;
		GTBranch *masterBranch = [GTBranch branchByLookingUpBranchNamed:@"master" inRepository:repository error:&error];
		expect(masterBranch).notTo.beNil();
		expect(error).to.beNil();

		GTBranch *trackingBranch = [masterBranch trackingBranchWithError:&error];
		expect(trackingBranch).notTo.beNil();
		expect(error).to.beNil();
	});

	it(@"should return nil for a local branch that doesn't track a remote branch", ^{
		NSError *error = nil;
		GTReference *otherRef = [GTReference referenceByCreatingReferenceNamed:@"refs/heads/yet-another-branch" fromReferenceTarget:@"6b0c1c8b8816416089c534e474f4c692a76ac14f" inRepository:repository error:&error];
		expect(otherRef).notTo.beNil();
		expect(error).to.beNil();

		GTBranch *otherBranch = [GTBranch branchWithReference:otherRef];
		expect(otherBranch).notTo.beNil();

		trackingBranch = [otherBranch trackingBranchWithError:&error];
		expect(trackingBranch).to.beNil();
		expect(error).to.beNil();
	});

	it(@"should return itself for a remote branch", ^{
		NSError *error = nil;
		GTReference *remoteRef = [GTReference referenceByLookingUpReferenceNamed:@"refs/remotes/origin/master" inRepository:repository error:&error];
		expect(remoteRef).notTo.beNil();
		expect(error).to.beNil();

		GTBranch *remoteBranch = [GTBranch branchWithReference:remoteRef];
		expect(remoteBranch).notTo.beNil();

		GTBranch *remoteTrackingBranch = [remoteBranch trackingBranchWithError:&error];
		expect(remoteTrackingBranch).to.equal(remoteBranch);
		expect(error).to.beNil();
	});
});

// TODO: Test branch renaming, branch upstream
//- (void)testCanRenameBranch {
//
//	NSError *error = nil;
//	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
//	STAssertNil(error, [error localizedDescription]);
//
//	NSArray *branches = [GTBranch listAllLocalBranchesInRepository:repo error:&error];
//	STAssertNotNil(branches, [error localizedDescription], nil);
//	STAssertEquals(2, (int)branches.count, nil);
//
//	NSString *newBranchName = [NSString stringWithFormat:@"%@%@", [GTBranch localNamePrefix], @"this_is_the_renamed_branch"];
//	GTBranch *firstBranch = [branches objectAtIndex:0];
//	NSString *originalBranchName = firstBranch.name;
//	BOOL success = [firstBranch.reference setName:newBranchName error:&error];
//	STAssertTrue(success, [error localizedDescription]);
//	STAssertEqualObjects(firstBranch.name, newBranchName, nil);
//
//	success = [firstBranch.reference setName:originalBranchName error:&error];
//	STAssertTrue(success, [error localizedDescription]);
//	STAssertEqualObjects(firstBranch.name, originalBranchName, nil);
//}

SpecEnd
