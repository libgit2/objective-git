//
//  GTRepository+PullSpec.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/28/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"
#import "GTUtilityFunctions.h"

#pragma mark - GTRepository+PullSpec

QuickSpecBegin(GTRepositoryPullSpec)

describe(@"pulling", ^{
	__block	GTRepository *notBareRepo;

	beforeEach(^{
		notBareRepo = self.bareFixtureRepository;
		expect(notBareRepo).notTo(beNil());
		// This repo is not really "bare" according to libgit2
		expect(@(notBareRepo.isBare)).to(beFalsy());
	});

	describe(@"from remote", ^{	// via local transport
		__block NSURL *remoteRepoURL;
		__block NSURL *localRepoURL;
		__block GTRepository *remoteRepo;
		__block GTRepository *localRepo;
		__block GTRemote *remote;
		__block	NSError *error;

		beforeEach(^{
			// Make a bare clone to serve as the remote
			remoteRepoURL = [notBareRepo.gitDirectoryURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"bare_remote_repo.git"];
			NSDictionary *options = @{ GTRepositoryCloneOptionsBare: @1 };
			remoteRepo = [GTRepository cloneFromURL:notBareRepo.gitDirectoryURL toWorkingDirectory:remoteRepoURL options:options error:&error transferProgressBlock:NULL checkoutProgressBlock:NULL];
			expect(error).to(beNil());
			expect(remoteRepo).notTo(beNil());
			expect(@(remoteRepo.isBare)).to(beTruthy()); // that's better

			localRepoURL = [remoteRepoURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"local_pull_repo"];
			expect(localRepoURL).notTo(beNil());

			// Local clone for testing pushes
			localRepo = [GTRepository cloneFromURL:remoteRepoURL toWorkingDirectory:localRepoURL options:nil error:&error transferProgressBlock:NULL checkoutProgressBlock:NULL];

			expect(error).to(beNil());
			expect(localRepo).notTo(beNil());

			GTConfiguration *configuration = [localRepo configurationWithError:&error];
			expect(error).to(beNil());
			expect(configuration).notTo(beNil());

			expect(@(configuration.remotes.count)).to(equal(@1));

			remote = configuration.remotes[0];
			expect(remote.name).to(equal(@"origin"));
		});

		afterEach(^{
			[NSFileManager.defaultManager removeItemAtURL:remoteRepoURL error:&error];
			expect(error).to(beNil());
			[NSFileManager.defaultManager removeItemAtURL:localRepoURL error:&error];
			expect(error).to(beNil());
			error = NULL;
		});

		context(@"when the local and remote branches are in sync", ^{
			it(@"should pull no commits", ^{
				GTBranch *masterBranch = localBranchWithName(@"master", localRepo);
				expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

				GTBranch *remoteMasterBranch = localBranchWithName(@"master", remoteRepo);
				expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

				// Push
				__block BOOL transferProgressed = NO;
				BOOL result = [localRepo pullBranch:masterBranch fromRemote:remote withOptions:nil error:&error progress:^(const git_transfer_progress *progress, BOOL *stop) {
					transferProgressed = YES;
				}];
				expect(error).to(beNil());
				expect(@(result)).to(beTruthy());
				expect(@(transferProgressed)).to(beFalsy()); // Local transport doesn't currently call progress callbacks

				// Same number of commits after pull, refresh branch from disk first
				remoteMasterBranch = localBranchWithName(@"master", remoteRepo);
				expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@3));
			});
		});

	});

});

QuickSpecEnd
