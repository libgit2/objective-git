//
//  GTRemotePushSpec.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 11/14/2014.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"
#import "GTUtilityFunctions.h"

#pragma mark - GTRemotePushSpec

QuickSpecBegin(GTRemotePushSpec)

describe(@"pushing", ^{
	__block	GTRepository *notBareRepo;

	beforeEach(^{
		notBareRepo = self.bareFixtureRepository;
		expect(notBareRepo).notTo(beNil());
		// This repo is not really "bare" according to libgit2
		expect(@(notBareRepo.isBare)).to(beFalsy());
	});

	describe(@"to remote", ^{	// via local transport
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
			remoteRepo = [GTRepository cloneFromURL:notBareRepo.gitDirectoryURL toWorkingDirectory:remoteRepoURL options:options error:&error transferProgressBlock:NULL];
			expect(error).to(beNil());
			expect(remoteRepo).notTo(beNil());
			expect(@(remoteRepo.isBare)).to(beTruthy()); // that's better

			localRepoURL = [remoteRepoURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"local_push_repo"];
			expect(localRepoURL).notTo(beNil());

			// Local clone for testing pushes
			localRepo = [GTRepository cloneFromURL:remoteRepoURL toWorkingDirectory:localRepoURL options:nil error:&error transferProgressBlock:NULL];

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
			it(@"should push no commits", ^{
				GTBranch *masterBranch = localBranchWithName(@"master", localRepo);
				expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

				GTBranch *remoteMasterBranch = localBranchWithName(@"master", remoteRepo);
				expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

				// Push
				__block BOOL transferProgressed = NO;
				BOOL result = [localRepo pushBranch:masterBranch toRemote:remote withOptions:nil error:&error progress:^(unsigned int current, unsigned int total, size_t bytes, BOOL *stop) {
					transferProgressed = YES;
				}];
				expect(error).to(beNil());
				expect(@(result)).to(beTruthy());
				expect(@(transferProgressed)).to(beTruthy());

				// Same number of commits after push, refresh branch first
				remoteMasterBranch = localBranchWithName(@"master", remoteRepo);
				expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@3));
			});
		});

		it(@"can push one commit", ^{
			// Create a new commit in the local repo
			NSString *testData = @"Test";
			NSString *fileName = @"test.txt";
			GTCommit *testCommit = createCommitInRepository(@"Test commit", [testData dataUsingEncoding:NSUTF8StringEncoding], fileName, localRepo);
			expect(testCommit).notTo(beNil());

			// Refetch master branch to ensure the commit count is accurate
			GTBranch *masterBranch = localBranchWithName(@"master", localRepo);
			expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@4));

			// Number of commits on tracking branch before push
			BOOL success = NO;
			GTBranch *localTrackingBranch = [masterBranch trackingBranchWithError:&error success:&success];
			expect(error).to(beNil());
			expect(@(success)).to(beTruthy());
			expect(@([localTrackingBranch numberOfCommitsWithError:NULL])).to(equal(@3));

			// Number of commits on remote before push
			GTBranch *remoteMasterBranch = localBranchWithName(@"master", remoteRepo);
			expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

			// Push
			__block BOOL transferProgressed = NO;
			BOOL result = [localRepo pushBranch:masterBranch toRemote:remote withOptions:nil error:&error progress:^(unsigned int current, unsigned int total, size_t bytes, BOOL *stop) {
				transferProgressed = YES;
			}];
			expect(error).to(beNil());
			expect(@(result)).to(beTruthy());
			expect(@(transferProgressed)).to(beTruthy());

			// Number of commits on tracking branch after push
			localTrackingBranch = [masterBranch trackingBranchWithError:&error success:&success];
			expect(error).to(beNil());
			expect(@(success)).to(beTruthy());
			expect(@([localTrackingBranch numberOfCommitsWithError:NULL])).to(equal(@4));

			// Refresh remote master branch to ensure the commit count is accurate
			remoteMasterBranch = localBranchWithName(@"master", remoteRepo);

			// Number of commits in remote repo after push
			expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@4));

			// Verify commit is in remote
			GTCommit *pushedCommit = [remoteRepo lookUpObjectByOID:testCommit.OID objectType:GTObjectTypeCommit error:&error];
			expect(error).to(beNil());
			expect(pushedCommit).notTo(beNil());
			expect(pushedCommit.OID).to(equal(testCommit.OID));

			GTTreeEntry *entry = [[pushedCommit tree] entryWithName:fileName];
			expect(entry).notTo(beNil());

			GTBlob *fileData = (GTBlob *)[entry GTObject:&error];
			expect(error).to(beNil());
			expect(fileData).notTo(beNil());
			expect(fileData.content).to(equal(testData));
		});

		it(@"can push two branches", ^{
			// refs/heads/master on local
			GTBranch *branch1 = localBranchWithName(@"master", localRepo);

			// Create refs/heads/new_master on local
			[localRepo createReferenceNamed:@"refs/heads/new_master" fromReference:branch1.reference message:@"Create new_master branch" error:&error];
			GTBranch *branch2 = localBranchWithName(@"new_master", localRepo);

			BOOL result = [localRepo pushBranches:@[ branch1, branch2 ] toRemote:remote withOptions:nil error:&error progress:NULL];
			expect(error).to(beNil());
			expect(@(result)).to(beTruthy());
		});
	});

});

QuickSpecEnd
