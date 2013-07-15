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
	repository = [self fixtureRepositoryNamed:@"Test_App"];
	expect(repository).notTo.beNil();

	NSError *error = nil;
	masterBranch = [repository currentBranchWithError:&error];
	expect(masterBranch).notTo.beNil();
	expect(error).to.beNil();

	BOOL success = NO;
	trackingBranch = [masterBranch trackingBranchWithError:&error success:&success];
	expect(trackingBranch).notTo.equal(masterBranch);
	expect(success).to.beTruthy();
	expect(error).to.beNil();
});

describe(@"shortName", ^{
	it(@"should use just the branch name for a local branch", ^{
		expect(masterBranch.shortName).to.equal(@"master");
	});

	it(@"should not include the remote name for a tracking branch", ^{
		expect(trackingBranch.shortName).to.equal(@"master");
	});
});

describe(@"remoteName", ^{
	it(@"should return nil for a local branch", ^{
		expect(masterBranch.remoteName).to.beNil();
	});

	it(@"should return the remote name for a tracking branch", ^{
		expect(trackingBranch.remoteName).to.equal(@"origin");
	});
});

describe(@"branchType", ^{
	it(@"should be GTBranchTypeLocal for a local branch", ^{
		expect(masterBranch.branchType).to.equal(GTBranchTypeLocal);
	});

	it(@"should be GTBranchTypeRemote for a tracking branch", ^{
		expect(trackingBranch.branchType).to.equal(GTBranchTypeRemote);
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

SpecEnd
