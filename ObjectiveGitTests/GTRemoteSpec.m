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

QuickSpecBegin(GTRemoteSpec)

__block GTRemote *remote = nil;
__block GTRepository *repository = nil;
NSString *fetchRefspec = @"+refs/heads/*:refs/remotes/origin/*";

qck_beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo(beNil());

	NSError *error = nil;
	GTConfiguration *configuration = [repository configurationWithError:&error];
	expect(configuration).notTo(beNil());
	expect(error).to(beNil());

	expect(@(configuration.remotes.count)).to(beGreaterThanOrEqualTo(@1));

	remote = configuration.remotes[0];
	expect(remote.name).to(equal(@"origin"));
});

qck_describe(@"properties", ^{
	qck_it(@"should have values", ^{
		expect([NSValue valueWithPointer:remote.git_remote]).notTo(equal([NSValue valueWithPointer:NULL]));
		expect(remote.name).to(equal(@"origin"));
		expect(remote.URLString).to(equal(@"git@github.com:github/Test_App.git"));

		expect(remote.fetchRefspecs).to(equal(@[ fetchRefspec ]));
	});
});

qck_describe(@"updating", ^{
	qck_it(@"URL string", ^{
		expect(remote.URLString).to(equal(@"git@github.com:github/Test_App.git"));

		NSString *newURLString = @"https://github.com/github/Test_App.git";

		__block NSError *error = nil;
		expect(@([remote updateURLString:newURLString error:&error])).to(beTruthy());
		expect(error).to(beNil());

		expect(remote.URLString).to(equal(newURLString));
	});

	qck_it(@"fetch refspecs", ^{
		expect(remote.fetchRefspecs).to(equal(@[ fetchRefspec ]));

		NSString *newFetchRefspec = @"+refs/heads/master:refs/remotes/origin/master";

		__block NSError *error = nil;
		expect(@([remote addFetchRefspec:newFetchRefspec error:&error])).to(beTruthy());
		expect(error).to(beNil());

		expect(remote.fetchRefspecs).to(equal((@[ fetchRefspec, newFetchRefspec ])));
	});
});

qck_describe(@"network operations", ^{
	__block NSURL *repositoryURL;
	__block NSURL *fetchingRepoURL;
	__block GTRepository *fetchingRepo;
	__block NSArray *remoteNames;
	__block NSString *remoteName;

	qck_beforeEach(^{
		repository = self.bareFixtureRepository;
		expect(@(repository.isBare)).to(beFalsy()); // yeah right
		repositoryURL = repository.gitDirectoryURL;
		NSURL *fixturesURL = repositoryURL.URLByDeletingLastPathComponent;
		fetchingRepoURL = [fixturesURL URLByAppendingPathComponent:@"fetchrepo"];

		NSError *error = nil;
		fetchingRepo = [GTRepository cloneFromURL:repositoryURL toWorkingDirectory:fetchingRepoURL options:nil error:&error transferProgressBlock:nil checkoutProgressBlock:nil];
		expect(fetchingRepo).notTo(beNil());
		expect(error).to(beNil());

		remoteNames = [fetchingRepo remoteNamesWithError:&error];
		expect(error).to(beNil());
		expect(@(remoteNames.count)).to(beGreaterThanOrEqualTo(@1));

		remoteName = remoteNames[0];
	});

	qck_afterEach(^{
		[NSFileManager.defaultManager removeItemAtURL:fetchingRepoURL error:NULL];
	});

	qck_describe(@"-remoteWithName:inRepository:error", ^{
		qck_it(@"should return existing remotes", ^{
			NSError *error = nil;

			GTRemote *originRemote = [GTRemote remoteWithName:remoteName inRepository:fetchingRepo error:&error];
			expect(error).to(beNil());
			expect(originRemote).notTo(beNil());
			expect(originRemote.name).to(equal(@"origin"));
			expect(originRemote.URLString).to(equal(repositoryURL.path));
		});

		qck_it(@"should fail for non-existent remotes", ^{
			NSError *error = nil;

			GTRemote *originRemote = [GTRemote remoteWithName:@"blork" inRepository:fetchingRepo error:&error];
			expect(error).notTo(beNil());
			expect(originRemote).to(beNil());
		});
	});

	qck_describe(@"-createRemoteWithName:url:inRepository:error", ^{
		qck_it(@"should allow creating new remotes", ^{
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

	// Helper to quickly create commits
	GTCommit *(^createCommitInRepository)(NSString *, NSData *, NSString *, GTRepository *) = ^(NSString *message, NSData *fileData, NSString *fileName, GTRepository *repo) {
		GTTreeBuilder *treeBuilder = [[GTTreeBuilder alloc] initWithTree:nil repository:repo error:nil];
		[treeBuilder addEntryWithData:fileData fileName:fileName fileMode:GTFileModeBlob error:nil];

		GTTree *testTree = [treeBuilder writeTree:nil];

		// We need the parent commit to make the new one
		GTReference *headReference = [repo headReferenceWithError:nil];

		GTEnumerator *commitEnum = [[GTEnumerator alloc] initWithRepository:repo error:nil];
		[commitEnum pushSHA:[headReference targetSHA] error:nil];
		GTCommit *parent = [commitEnum nextObject];

		GTCommit *testCommit = [repo createCommitWithTree:testTree message:message parents:@[parent] updatingReferenceNamed:headReference.name error:nil];
		expect(testCommit).notTo(beNil());

		return testCommit;
	};
});

QuickSpecEnd
