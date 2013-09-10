//
//  GTRemoteSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2013-09-06
//

#import "GTRemote.h"

SpecBegin(GTRemote)

__block NSURL *fetchingRepoURL;
__block GTRepository *masterRepo;
__block GTRepository *fetchingRepo;
__block NSArray *remoteNames;
__block NSString *remoteName;

beforeEach(^{
	masterRepo = [self fixtureRepositoryNamed:@"testrepo.git"];

	NSURL *masterRepoURL = masterRepo.gitDirectoryURL;
	NSURL *fixturesURL = masterRepoURL.URLByDeletingLastPathComponent;
	fetchingRepoURL = [fixturesURL URLByAppendingPathComponent:@"fetchrepo"];

	// Make sure there's no leftover
	[NSFileManager.defaultManager removeItemAtURL:fetchingRepoURL error:nil];

	NSError *error = nil;
	fetchingRepo = [GTRepository cloneFromURL:masterRepoURL toWorkingDirectory:fetchingRepoURL barely:NO withCheckout:YES error:&error transferProgressBlock:nil checkoutProgressBlock:nil];
	expect(fetchingRepo).notTo.beNil();
	expect(error.localizedDescription).to.beNil();

	remoteNames = [fetchingRepo remoteNamesWithError:&error];
	expect(error.localizedDescription).to.beNil();
	expect(remoteNames.count).to.beGreaterThanOrEqualTo(1);

	remoteName = remoteNames[0];
});

afterEach(^{
	[NSFileManager.defaultManager removeItemAtURL:fetchingRepoURL error:NULL];
});

describe(@"-remoteWithName:inRepository:error", ^{
	it(@"should return existing remotes", ^{
		NSError *error = nil;

		GTRemote *originRemote = [GTRemote remoteWithName:remoteName inRepository:fetchingRepo error:&error];
		expect(error.localizedDescription).to.beNil();
		expect(originRemote).notTo.beNil();
	});

	it(@"should fail for non-existent remotes", ^{
		NSError *error = nil;

		GTRemote *originRemote = [GTRemote remoteWithName:@"blork" inRepository:fetchingRepo error:&error];
		expect(error.localizedDescription).notTo.beNil();
		expect(originRemote).to.beNil();
	});
});

describe(@"-createRemoteWithName:url:inRepository:error", ^{
	it(@"should allow creating new remotes", ^{
		NSError *error = nil;
		GTRemote *remote = [GTRemote createRemoteWithName:@"newremote" url:@"git://user@example.com/testrepo.git" inRepository:fetchingRepo	error:&error];
		expect(error.localizedDescription).to.beNil();
		expect(remote).notTo.beNil();

		GTRemote *newRemote = [GTRemote remoteWithName:@"newremote" inRepository:fetchingRepo error:&error];
		expect(error.localizedDescription).to.beNil();
		expect(newRemote).notTo.beNil();
	});
});

describe(@"-fetchWithError:credentials:progress:", ^{
	it(@"allows remotes to be fetched", ^{
		NSError *error = nil;
		GTRemote *remote = [GTRemote remoteWithName:remoteName inRepository:fetchingRepo error:nil]; // Tested above

		BOOL result = [remote fetchWithError:&error credentials:nil progress:nil];
		expect(error.localizedDescription).to.beNil();
		expect(result).to.beTruthy();
	});
});

SpecEnd
