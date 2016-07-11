//
//  GTRepository+PullSpec.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/28/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <Nimble/Nimble-Swift.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"
#import "GTUtilityFunctions.h"

#pragma mark - GTRepository+PullSpec

QuickSpecBegin(GTRepositoryPullSpec)

describe(@"pull", ^{
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
			remoteRepo = [GTRepository cloneFromURL:notBareRepo.gitDirectoryURL toWorkingDirectory:remoteRepoURL options:options error:&error transferProgressBlock:NULL];
			expect(error).to(beNil());
			expect(remoteRepo).notTo(beNil());
			expect(@(remoteRepo.isBare)).to(beTruthy()); // that's better

			localRepoURL = [remoteRepoURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"local_pull_repo"];
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
			[NSFileManager.defaultManager removeItemAtURL:remoteRepoURL error:NULL];
			[NSFileManager.defaultManager removeItemAtURL:localRepoURL error:NULL];
			error = NULL;
		});

		context(@"when the local and remote branches are in sync", ^{
			it(@"should pull no commits", ^{
				GTBranch *masterBranch = localBranchWithName(@"master", localRepo);
				expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

				GTBranch *remoteMasterBranch = localBranchWithName(@"master", remoteRepo);
				expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

				// Pull
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

/* pending tests break build on travis
		/// Unborn
		/// Can't get a GTBranch reference wrapping HEAD when its symref is unborn
		pending(@"into an empty repo", ^{
			// Create an empty local repo
			localRepoURL = [remoteRepoURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"empty_pull_repo"];
			NSLog(@"localRepoURL: %@", localRepoURL);
			NSDictionary *options = @{ GTRepositoryInitOptionsOriginURLString: [remoteRepoURL absoluteString] };
			localRepo = [GTRepository initializeEmptyRepositoryAtFileURL:localRepoURL options:options error:&error];
			expect(localRepo).toNot(beNil());
			expect(error).to(beNil());

			// Verify unborn
			expect(@(localRepo.isHEADUnborn)).to(beTruthy());

			// Configure tracking
			GTConfiguration *configuration = [localRepo configurationWithError:&error];
			expect(configuration).toNot(beNil());
			expect(error).to(beNil());
			[configuration setString:@"origin" forKey:@"branch.master.remote"];
			[configuration setString:@"refs/heads/master" forKey:@"branch.master.merge"];

			GTReference *head = [localRepo headReferenceWithError:&error];
			expect(head).toNot(beNil());
			expect(error).to(beNil());

//			GTBranch *masterBranch = localBranchWithName(@"master", localRepo);
			GTBranch *masterBranch = [localRepo currentBranchWithError:&error];
			expect(masterBranch).toNot(beNil());

			// Pull
			__block BOOL transferProgressed = NO;
			BOOL result = [localRepo pullBranch:masterBranch fromRemote:remote withOptions:nil error:&error progress:^(const git_transfer_progress *progress, BOOL *stop) {
				transferProgressed = YES;
			}];
			expect(@(result)).to(beTruthy());
			expect(error).to(beNil());
			expect(@(transferProgressed)).to(beFalsy()); // Local transport doesn't currently call progress callbacks

//			GTReference *head = [localRepo headReferenceWithError:&error];
//			expect(head).toNot(beNil());

		});
*/

		/// Fast-Forward Merge
		///
		/// Stages a pull by modifying a clone, resetting it back in history
		/// then using pull to bring the repos back in sync.
		it(@"fast-forwards one commit", ^{
			GTBranch *masterBranch = localBranchWithName(@"master", localRepo);
			expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

			// Reset local master back one commit
			GTCommit *commit = [localRepo lookUpObjectByRevParse:@"HEAD^" error:&error];
			BOOL success = [localRepo resetToCommit:commit resetType:GTRepositoryResetTypeHard error:&error];
			expect(@(success)).to(beTruthy());
			expect(error).to(beNil());

			// Verify rollback, must refresh branch from disk
			masterBranch = localBranchWithName(@"master", localRepo);
			expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@2));

			// HEADs point to different objects
			expect([[localRepo headReferenceWithError:NULL] OID])
				.toNot(equal([[remoteRepo headReferenceWithError:NULL] OID]));

			// Remote has 3 commits
			GTBranch *remoteMasterBranch = localBranchWithName(@"master", remoteRepo);
			expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

			// Pull
			__block BOOL transferProgressed = NO;
			BOOL result = [localRepo pullBranch:masterBranch fromRemote:remote withOptions:nil error:&error progress:^(const git_transfer_progress *progress, BOOL *stop) {
				transferProgressed = YES;
			}];
			expect(error).to(beNil());
			expect(@(result)).to(beTruthy());
			expect(@(transferProgressed)).to(beFalsy()); // Local transport doesn't currently call progress callbacks

			// Verify same number of commits after pull, refresh branch from disk first
			masterBranch = localBranchWithName(@"master", localRepo);
			expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

			// Verify HEADs are in sync
			expect([[localRepo headReferenceWithError:NULL] OID])
				.to(equal([[remoteRepo headReferenceWithError:NULL] OID]));
		});

		/// Normal Merge
		it(@"merges the upstream changes", ^{
			// 3 commits
			GTBranch *masterBranch = localBranchWithName(@"master", localRepo);
			expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@3));

			// Create a new commit in the local repo
			GTCommit *localCommit = createCommitInRepository(@"Local commit", [@"Test" dataUsingEncoding:NSUTF8StringEncoding], @"test.txt", localRepo);
			expect(localCommit).notTo(beNil());

			// 4 commits
			masterBranch = localBranchWithName(@"master", localRepo);
			expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@4));

			localCommit = [localRepo lookUpObjectByOID:localCommit.OID objectType:GTObjectTypeCommit error:&error];
			expect(localCommit).notTo(beNil());
			expect(error).to(beNil());

			// Create a new commit in the remote repo
			GTCommit *upstreamCommit = createCommitInRepository(@"Upstream commit", [@"# So Fancy" dataUsingEncoding:NSUTF8StringEncoding], @"fancy.md", remoteRepo);
			expect(upstreamCommit).notTo(beNil());

			masterBranch = localBranchWithName(@"master", localRepo);

			// Validate there is one unique local commit before merge
			BOOL success = NO;
			GTBranch *remoteTrackingBranch = [masterBranch trackingBranchWithError:&error success:&success];
			expect(@(success)).to(beTrue());
			expect(error).to(beNil());
			expect(remoteTrackingBranch).toNot(beNil());

			NSArray *uniqueLocalCommits = [localRepo localCommitsRelativeToRemoteBranch:remoteTrackingBranch error:&error];
			expect(uniqueLocalCommits).toNot(beNil());
			expect(error).to(beNil());
			expect(@(uniqueLocalCommits.count)).to(equal(@1));

			// Pull
			__block BOOL transferProgressed = NO;
			BOOL result = [localRepo pullBranch:masterBranch fromRemote:remote withOptions:nil error:&error progress:^(const git_transfer_progress *progress, BOOL *stop) {
				transferProgressed = YES;
			}];
			expect(@(result)).to(beTruthy());
			expect(error).to(beNil());
			expect(@(transferProgressed)).to(beTruthy());

			// Validate

			// 5 commits
			masterBranch = localBranchWithName(@"master", localRepo);
			expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@6));

			// We should have have an additional merge commit after the pull
			uniqueLocalCommits = [localRepo localCommitsRelativeToRemoteBranch:remoteTrackingBranch error:&error];
			expect(uniqueLocalCommits).toNot(beNil());
			expect(error).to(beNil());
			expect(@(uniqueLocalCommits.count)).to(equal(@3));
		});

		/// Conflict During Merge
		it(@"fails to merge when there is a conflict", ^{
			// Stage a conflict by adding the same file with different contents to both repos
			GTCommit *localCommit = createCommitInRepository(@"Local commit", [@"TestLocal" dataUsingEncoding:NSUTF8StringEncoding], @"test.txt", localRepo);
			expect(localCommit).notTo(beNil());
			GTCommit *remoteCommit = createCommitInRepository(@"Upstream commit", [@"TestUpstream" dataUsingEncoding:NSUTF8StringEncoding], @"test.txt", remoteRepo);
			expect(remoteCommit).notTo(beNil());

			GTBranch *masterBranch = localBranchWithName(@"master", localRepo);

			// Pull
			__block BOOL transferProgressed = NO;
			BOOL result = [localRepo pullBranch:masterBranch fromRemote:remote withOptions:nil error:&error progress:^(const git_transfer_progress *progress, BOOL *stop) {
				transferProgressed = YES;
			}];
			NSString *fileContents = [NSString stringWithContentsOfURL:[localRepo.fileURL URLByAppendingPathComponent:@"test.txt"] encoding:NSUTF8StringEncoding error:nil];
			expect(@(result)).to(beFalsy());
			expect(error.domain).to(equal(@"GTGitErrorDomain"));
			expect(error.userInfo[GTPullMergeConflictedFiles]).to(equal(@[@"test.txt"]));
			expect(fileContents).notTo(equal(@"TestLocal"));
			expect([localRepo mergeHeadEntriesWithError:nil]).to(equal(@[remoteCommit.OID]));
			expect([localRepo preparedMessageWithError:nil]).to(beginWith(@"Merge commit"));
			expect(error.localizedDescription).to(equal(@"Merge conflict"));
			expect(@(transferProgressed)).to(beTruthy());
		});

	});

});

QuickSpecEnd
