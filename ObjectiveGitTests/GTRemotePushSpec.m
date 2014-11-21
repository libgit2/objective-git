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

// Helper to quickly create commits
GTCommit *(^createCommitInRepository)(NSString *, NSData *, NSString *, GTRepository *) = ^ GTCommit * (NSString *message, NSData *fileData, NSString *fileName, GTRepository *repo) {
	GTTreeBuilder *treeBuilder = [[GTTreeBuilder alloc] initWithTree:nil error:nil];
	[treeBuilder addEntryWithData:fileData fileName:fileName fileMode:GTFileModeBlob error:nil];

	GTTree *testTree = [treeBuilder writeTreeToRepository:repo error:nil];

	// We need the parent commit to make the new one
	GTReference *headReference = [repo headReferenceWithError:nil];

	GTEnumerator *commitEnum = [[GTEnumerator alloc] initWithRepository:repo error:nil];
	[commitEnum pushSHA:[headReference targetSHA] error:nil];
	GTCommit *parent = [commitEnum nextObject];

	GTCommit *testCommit = [repo createCommitWithTree:testTree message:message parents:@[ parent ] updatingReferenceNamed:headReference.name error:nil];
	expect(testCommit).notTo(beNil());

	return testCommit;
};

GTBranch *(^localBranchWithName)(NSString *, GTRepository *) = ^ GTBranch * (NSString *branchName, GTRepository *repo) {
	NSString *reference = [GTBranch.localNamePrefix stringByAppendingString:branchName];
	NSArray *branches = [repo branchesWithPrefix:reference error:NULL];
	expect(branches).notTo(beNil());
	expect(@(branches.count)).to(equal(@1));
	expect(((GTBranch *)branches[0]).shortName).to(equal(branchName));

	return branches[0];
};

#pragma mark - GTRemotePushSpec

QuickSpecBegin(GTRemotePushSpec)

describe(@"pushing", ^{
	__block GTRepository *localRepo;
	__block GTRepository *remoteRepo;
	__block	GTRepository *notBareRepo;
	__block GTRemote *remote;
	__block NSURL *remoteRepoURL;
	__block NSURL *localRepoURL;
	__block	NSError *error;

	beforeEach(^{
		// This repo is not really "bare"
		notBareRepo = self.bareFixtureRepository;
		expect(notBareRepo).notTo(beNil());
		expect(@(notBareRepo.isBare)).to(beFalse());
	});

	describe(@"to remote", ^{	// via local transport
		beforeEach(^{
			// Make a bare clone to serve as the remote
			remoteRepoURL = [notBareRepo.gitDirectoryURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"bare_remote_repo.git"];
			NSDictionary *options = @{ GTRepositoryCloneOptionsBare: @1 };
			remoteRepo = [GTRepository cloneFromURL:notBareRepo.gitDirectoryURL toWorkingDirectory:remoteRepoURL options:options error:&error transferProgressBlock:NULL checkoutProgressBlock:NULL];
			expect(error).to(beNil());
			expect(remoteRepo).notTo(beNil());
			expect(@(remoteRepo.isBare)).to(beTruthy()); // that's better

			localRepoURL = [remoteRepoURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"local_push_repo"];
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
			[NSFileManager.defaultManager removeItemAtURL:remoteRepoURL error:NULL];
			[NSFileManager.defaultManager removeItemAtURL:localRepoURL error:NULL];
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
				expect(@(transferProgressed)).to(beFalse()); // Local transport doesn't currently call progress callbacks

				// Same number of commits after push, refresh branch first
				remoteMasterBranch = localBranchWithName(@"master", remoteRepo);
				expect(@([remoteMasterBranch numberOfCommitsWithError:NULL])).to(equal(@3));
			});
		});

		it(@"can push one commit", ^{
			// Create a new commit in the master repo
			NSString *testData = @"Test";
			NSString *fileName = @"test.txt";
			GTCommit *testCommit = createCommitInRepository(@"Test commit", [testData dataUsingEncoding:NSUTF8StringEncoding], fileName, localRepo);
			expect(testCommit).notTo(beNil());

			// Refetch master branch to ensure the commit count is accurate
			GTBranch *masterBranch = localBranchWithName(@"master", localRepo);
			expect(@([masterBranch numberOfCommitsWithError:NULL])).to(equal(@4));

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
			expect(@(transferProgressed)).to(beFalse()); // Local transport doesn't currently call progress callbacks

			// Refetch master branch to ensure the commit count is accurate
			remoteMasterBranch = localBranchWithName(@"master", remoteRepo);

			// Number of commits on remote after push
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
			GTBranch *branch1 = localBranchWithName(@"master", localRepo);
			GTBranch *branch2 = localBranchWithName(@"packed", remoteRepo);

			BOOL result = [localRepo pushBranches:@[ branch1, branch2 ] toRemote:remote withOptions:nil error:&error progress:NULL];
			expect(error).to(beNil());
			expect(@(result)).to(beTruthy());
		});
	});

});

QuickSpecEnd
