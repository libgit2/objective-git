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

QuickSpecBegin(GTRemotePushSpec)

describe(@"push to remote", ^{
	__block GTRepository *localRepo;
	__block GTRepository *remoteRepo;
	__block GTRemote *remote;
	__block NSURL *notBareRepoURL;
	__block NSURL *remoteRepoFileURL;
	__block NSURL *localRepoURL;
	__block GTBranch *masterBranch;

	beforeEach(^{
		NSError *error = nil;

		// This repo is not really "bare"
		GTRepository *notBareRepo = self.bareFixtureRepository;
		expect(notBareRepo).notTo(beNil());
		expect(@(notBareRepo.isBare)).to(beFalse());

		// Make a bare clone to serve as the remote
		notBareRepoURL = [notBareRepo.gitDirectoryURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"barerepo.git"];
		NSDictionary *options = @{ GTRepositoryCloneOptionsBare: @(1) };
		remoteRepo = [GTRepository cloneFromURL:notBareRepo.gitDirectoryURL toWorkingDirectory:notBareRepoURL options:options error:&error transferProgressBlock:NULL checkoutProgressBlock:NULL];
		expect(error).to(beNil());
		expect(remoteRepo).notTo(beNil());
		expect(@(remoteRepo.isBare)).to(beTruthy()); // that's better

		NSURL *remoteRepoFileURL = remoteRepo.gitDirectoryURL;
		expect(remoteRepoFileURL).notTo(beNil());
		NSURL *localRepoURL = [remoteRepoFileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"localpushrepo"];
		expect(localRepoURL).notTo(beNil());

		// Ensure repo destination is clear before clone
		[NSFileManager.defaultManager removeItemAtURL:localRepoURL error:NULL];

		// Local clone for testing pushes
		localRepo = [GTRepository cloneFromURL:remoteRepoFileURL toWorkingDirectory:localRepoURL options:nil error:&error transferProgressBlock:NULL checkoutProgressBlock:NULL];

		expect(error).to(beNil());
		expect(localRepo).notTo(beNil());

		GTConfiguration *configuration = [localRepo configurationWithError:&error];
		expect(error).to(beNil());
		expect(configuration).notTo(beNil());

		expect(@(configuration.remotes.count)).to(equal(@1));

		remote = configuration.remotes[0];
		expect(remote.name).to(equal(@"origin"));

		// TODO: Verify tracking between local and remote branches
		NSArray *branches = [localRepo allBranchesWithError:&error];
		expect(error).to(beNil());
		expect(branches).notTo(beNil());

		masterBranch = branches[0];
		expect(masterBranch.shortName).to(equal(@"master"));
	});

	afterEach(^{
		[NSFileManager.defaultManager removeItemAtURL:notBareRepoURL error:NULL];
		[NSFileManager.defaultManager removeItemAtURL:remoteRepoFileURL error:NULL];
		[NSFileManager.defaultManager removeItemAtURL:localRepoURL error:NULL];
	});

	// Helper to quickly create commits
	GTCommit *(^createCommitInRepository)(NSString *, NSData *, NSString *, GTRepository *) = ^(NSString *message, NSData *fileData, NSString *fileName, GTRepository *repo) {
		GTTreeBuilder *treeBuilder = [[GTTreeBuilder alloc] initWithTree:nil error:nil];
		[treeBuilder addEntryWithData:fileData fileName:fileName fileMode:GTFileModeBlob error:nil];

		GTTree *testTree = [treeBuilder writeTreeToRepository:repo error:nil];

		// We need the parent commit to make the new one
		GTReference *headReference = [repo headReferenceWithError:nil];

		GTEnumerator *commitEnum = [[GTEnumerator alloc] initWithRepository:repo error:nil];
		[commitEnum pushSHA:[headReference targetSHA] error:nil];
		GTCommit *parent = [commitEnum nextObject];

		GTCommit *testCommit = [repo createCommitWithTree:testTree message:message parents:@[parent] updatingReferenceNamed:headReference.name error:nil];
		expect(testCommit).notTo(beNil());

		return testCommit;
	};

	describe(@"-pushBranch:toRemote:withOptions:error:progress:", ^{
		it(@"pushes nothing when the branch on local and remote are in sync", ^{
			NSError *error = nil;

			__block BOOL transferProgressed = NO;
			BOOL result = [localRepo pushBranch:masterBranch toRemote:remote withOptions:nil error:&error progress:^(unsigned int current, unsigned int total, size_t bytes, BOOL *stop) {
				transferProgressed = YES;
			}];
			expect(error).to(beNil());
			expect(@(result)).to(beTruthy());
			expect(@(transferProgressed)).to(beFalse()); // Local transport doesn't currently call progress callbacks
		});

		it(@"pushes a new local commit to the remote", ^{
			NSError *error = nil;

			// Create a new commit in the master repo
			NSString *testData = @"Test";
			NSString *fileName = @"test.txt";
			GTCommit *testCommit = createCommitInRepository(@"Test commit", [testData dataUsingEncoding:NSUTF8StringEncoding], fileName, localRepo);
			expect(testCommit).notTo(beNil());

			// Push
			__block BOOL transferProgressed = NO;
			BOOL result = [localRepo pushBranch:masterBranch toRemote:remote withOptions:nil error:&error progress:^(unsigned int current, unsigned int total, size_t bytes, BOOL *stop) {
				transferProgressed = YES;
			}];
			expect(error).to(beNil());
			expect(@(result)).to(beTruthy());
			expect(@(transferProgressed)).to(beFalse()); // Local transport doesn't currently call progress callbacks

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
	});

});

QuickSpecEnd
