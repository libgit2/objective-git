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

describe(@"push to local filesystem bare repo", ^{
	__block GTRepository *localRepo;
	__block GTRepository *remoteRepo;
	__block GTRemote *remote;
	__block NSURL *remoteRepoFileURL;
	__block NSURL *localRepoURL;

	beforeEach(^{
		NSError *error = nil;

		// This repo is not really "bare"
		GTRepository *notBareRepo = self.bareFixtureRepository;
		expect(notBareRepo).notTo(beNil());
		expect(@(notBareRepo.isBare)).to(beFalse());

		// Make a bare clone to serve as the remote
		NSURL *bareRepoURL = [notBareRepo.gitDirectoryURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"barerepo.git"];
		NSDictionary *options = @{ GTRepositoryCloneOptionsBare: @(1) };
		remoteRepo = [GTRepository cloneFromURL:notBareRepo.gitDirectoryURL toWorkingDirectory:bareRepoURL options:options error:&error transferProgressBlock:NULL checkoutProgressBlock:NULL];
		expect(error).to(beNil());
		expect(remoteRepo).notTo(beNil());
		expect(@(remoteRepo.isBare)).to(beTruthy()); // that's better

		NSURL *remoteRepoFileURL = remoteRepo.gitDirectoryURL;
		expect(remoteRepoFileURL).notTo(beNil());
		NSURL *localRepoURL = [remoteRepoFileURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:@"localpushrepo"];
		expect(localRepoURL).notTo(beNil());

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
	});

	afterEach(^{
		[NSFileManager.defaultManager removeItemAtURL:remoteRepoFileURL error:NULL];
		[NSFileManager.defaultManager removeItemAtURL:localRepoURL error:NULL];
	});

	describe(@"-pushBranch:toRemote:withOptions:error:progress:", ^{
		it(@"pushes nothing when the branch on local and remote are in sync", ^{
			NSError *error = nil;
			NSArray *branches = [localRepo allBranchesWithError:&error];
			expect(error).to(beNil());
			expect(branches).notTo(beNil());

			GTBranch *branch = branches[0];
			expect(branch.shortName).to(equal(@"master"));

			BOOL result = [localRepo pushBranch:branch toRemote:remote withOptions:nil error:&error progress:NULL];
			expect(error).to(beNil());
			expect(@(result)).to(beTruthy());
		});
	});

});

QuickSpecEnd
