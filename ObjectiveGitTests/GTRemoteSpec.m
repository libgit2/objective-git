//
//  GTRemoteSpec.m
//  ObjectiveGitFramework
//
//  Created by Alan Rogers on 16/10/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"
#import "GTUtilityFunctions.h"

QuickSpecBegin(GTRemoteSpec)

__block GTRemote *remote = nil;
__block GTRepository *repository = nil;
__block GTConfiguration *configuration = nil;
NSString *fetchRefspec = @"+refs/heads/*:refs/remotes/origin/*";

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo(beNil());

	NSError *error = nil;
	configuration = [repository configurationWithError:&error];
	expect(configuration).notTo(beNil());
	expect(error).to(beNil());

	expect(@(configuration.remotes.count)).to(beGreaterThanOrEqualTo(@1));

	remote = configuration.remotes[0];
	expect(remote.name).to(equal(@"origin"));
});

describe(@"properties", ^{
	it(@"should have values", ^{
		expect([NSValue valueWithPointer:remote.git_remote]).notTo(equal([NSValue valueWithPointer:NULL]));
		expect(remote.name).to(equal(@"origin"));
		expect(remote.URLString).to(equal(@"git@github.com:github/Test_App.git"));

		expect(remote.fetchRefspecs).to(equal(@[ fetchRefspec ]));
	});
});

describe(@"updating", ^{
	it(@"URL string", ^{
		expect(remote.URLString).to(equal(@"git@github.com:github/Test_App.git"));

		NSString *newURLString = @"https://github.com/github/Test_App.git";

		__block NSError *error = nil;
		expect(@([remote updateURLString:newURLString error:&error])).to(beTruthy());
		expect(error).to(beNil());

		// Reload remote from disk to pick up the change
		remote = configuration.remotes[0];

		expect(remote.URLString).to(equal(newURLString));
	});

	it(@"push URL string", ^{
		expect(remote.pushURLString).to(beNil());
		
		NSString *newURLString = @"https://github.com/github/Test_App.git";
		
		__block NSError *error = nil;
		expect(@([remote updatePushURLString:newURLString error:&error])).to(beTruthy());
		expect(error).to(beNil());
		
		// Reload remote from disk to pick up the change
		remote = configuration.remotes[0];
		
		expect(remote.pushURLString).to(equal(newURLString));
	});

	it(@"fetch refspecs", ^{
		expect(remote.fetchRefspecs).to(equal(@[ fetchRefspec ]));

		NSString *newFetchRefspec = @"+refs/heads/master:refs/remotes/origin/master";

		__block NSError *error = nil;
		expect(@([remote addFetchRefspec:newFetchRefspec error:&error])).to(beTruthy());
		expect(error).to(beNil());

		// Reload remote from disk to pick up the change
		remote = configuration.remotes[0];

		expect(remote.fetchRefspecs).to(equal((@[ fetchRefspec, newFetchRefspec ])));
	});
});

describe(@"network operations", ^{
	__block NSURL *repositoryURL;
	__block NSURL *fetchingRepoURL;
	__block GTRepository *fetchingRepo;
	__block NSArray *remoteNames;
	__block NSString *remoteName;

	beforeEach(^{
		repository = self.bareFixtureRepository;
		expect(@(repository.isBare)).to(beFalsy()); // yeah right
		repositoryURL = repository.gitDirectoryURL;
		NSURL *fixturesURL = repositoryURL.URLByDeletingLastPathComponent;
		fetchingRepoURL = [fixturesURL URLByAppendingPathComponent:@"fetchrepo"];

		NSError *error = nil;
		fetchingRepo = [GTRepository cloneFromURL:repositoryURL toWorkingDirectory:fetchingRepoURL options:nil error:&error transferProgressBlock:nil];
		expect(fetchingRepo).notTo(beNil());
		expect(error).to(beNil());

		remoteNames = [fetchingRepo remoteNamesWithError:&error];
		expect(error).to(beNil());
		expect(@(remoteNames.count)).to(beGreaterThanOrEqualTo(@1));

		remoteName = remoteNames[0];
	});

	afterEach(^{
		[NSFileManager.defaultManager removeItemAtURL:fetchingRepoURL error:NULL];
	});

	describe(@"-remoteWithName:inRepository:error", ^{
		it(@"should return existing remotes", ^{
			NSError *error = nil;

			GTRemote *originRemote = [GTRemote remoteWithName:remoteName inRepository:fetchingRepo error:&error];
			expect(error).to(beNil());
			expect(originRemote).notTo(beNil());
			expect(originRemote.name).to(equal(@"origin"));
			expect(originRemote.URLString).to(equal(repositoryURL.path));
		});

		it(@"should fail for non-existent remotes", ^{
			NSError *error = nil;

			GTRemote *originRemote = [GTRemote remoteWithName:@"blork" inRepository:fetchingRepo error:&error];
			expect(error).notTo(beNil());
			expect(originRemote).to(beNil());
		});
	});

	describe(@"-createRemoteWithName:url:inRepository:error", ^{
		it(@"should allow creating new remotes", ^{
			NSError *error = nil;
			GTRemote *remote = [GTRemote createRemoteWithName:@"newremote" URLString:@"git://user@example.com/testrepo.git" inRepository:fetchingRepo error:&error];
			expect(error).to(beNil());
			expect(remote).notTo(beNil());

			GTRemote *newRemote = [GTRemote remoteWithName:@"newremote" inRepository:fetchingRepo error:&error];
			expect(error).to(beNil());
			expect(newRemote).notTo(beNil());
			expect(newRemote.URLString).to(equal(@"git://user@example.com/testrepo.git"));
		});
	});

	describe(@"-[GTRepository fetchRemote:withOptions:error:progress:]", ^{
		it(@"allows remotes to be fetched", ^{
			NSError *error = nil;
			GTRemote *remote = [GTRemote remoteWithName:remoteName inRepository:fetchingRepo error:nil]; // Tested above

			BOOL result = [fetchingRepo fetchRemote:remote withOptions:nil error:&error progress:nil];
			expect(error).to(beNil());
			expect(@(result)).to(beTruthy());
		});

		it(@"brings in new commits", ^{
			NSError *error = nil;

			// Create a new commit in the master repo
			NSString *testData = @"Test";
			NSString *fileName = @"test.txt";

			GTCommit *testCommit = createCommitInRepository(@"Test commit", [testData dataUsingEncoding:NSUTF8StringEncoding], fileName, repository);

			// Now issue a fetch from the fetching repo
			GTRemote *remote = [GTRemote remoteWithName:remoteName inRepository:fetchingRepo error:nil];

			__block unsigned int receivedObjects = 0;
			__block BOOL transferProgressed = NO;
			BOOL success = [fetchingRepo fetchRemote:remote withOptions:nil error:&error progress:^(const git_transfer_progress *stats, BOOL *stop) {
				receivedObjects += stats->received_objects;
				transferProgressed = YES;
			}];
			expect(error).to(beNil());
			expect(@(success)).to(beTruthy());
			expect(@(transferProgressed)).to(beTruthy());
			expect(@(receivedObjects)).to(beGreaterThan(@0));

			GTCommit *fetchedCommit = [fetchingRepo lookUpObjectByOID:testCommit.OID objectType:GTObjectTypeCommit error:&error];
			expect(error).to(beNil());
			expect(fetchedCommit).notTo(beNil());

			GTTreeEntry *entry = [[fetchedCommit tree] entryWithName:fileName];
			expect(entry).notTo(beNil());

			GTBlob *fileData = (GTBlob *)[entry GTObject:&error];
			expect(error).to(beNil());
			expect(fileData).notTo(beNil());
			expect(fileData.content).to(equal(testData));
		});
	});
});

QuickSpecEnd
