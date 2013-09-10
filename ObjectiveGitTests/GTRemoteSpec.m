//
//  GTRemoteSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2013-09-06
//

#import "GTRemote.h"

SpecBegin(GTRemote)

__block NSURL *masterRepoURL;
__block NSURL *fetchingRepoURL;
__block GTRepository *masterRepo;
__block GTRepository *fetchingRepo;
__block NSArray *remoteNames;
__block NSString *remoteName;

beforeEach(^{
	masterRepo = [self fixtureRepositoryNamed:@"testrepo.git"];

	masterRepoURL = masterRepo.gitDirectoryURL;
	NSURL *fixturesURL = masterRepoURL.URLByDeletingLastPathComponent;
	fetchingRepoURL = [fixturesURL URLByAppendingPathComponent:@"fetchrepo"];

	// Make sure there's no leftover
	[NSFileManager.defaultManager removeItemAtURL:fetchingRepoURL error:nil];

	NSError *error = nil;
	fetchingRepo = [GTRepository cloneFromURL:masterRepoURL toWorkingDirectory:fetchingRepoURL barely:NO withCheckout:YES error:&error transferProgressBlock:nil checkoutProgressBlock:nil];
	expect(fetchingRepo).notTo.beNil();
	expect(error).to.beNil();

	remoteNames = [fetchingRepo remoteNamesWithError:&error];
	expect(error).to.beNil();
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
		expect(error).to.beNil();
		expect(originRemote).notTo.beNil();
	});

	it(@"should fail for non-existent remotes", ^{
		NSError *error = nil;

		GTRemote *originRemote = [GTRemote remoteWithName:@"blork" inRepository:fetchingRepo error:&error];
		expect(error).notTo.beNil();
		expect(originRemote).to.beNil();
	});
});

describe(@"-createRemoteWithName:url:inRepository:error", ^{
	it(@"should allow creating new remotes", ^{
		NSError *error = nil;
		GTRemote *remote = [GTRemote createRemoteWithName:@"newremote" url:@"git://user@example.com/testrepo.git" inRepository:fetchingRepo	error:&error];
		expect(error).to.beNil();
		expect(remote).notTo.beNil();

		GTRemote *newRemote = [GTRemote remoteWithName:@"newremote" inRepository:fetchingRepo error:&error];
		expect(error).to.beNil();
		expect(newRemote).notTo.beNil();
	});
});

describe(@"-fetchWithError:credentials:progress:", ^{
	it(@"allows remotes to be fetched", ^{
		NSError *error = nil;
		GTRemote *remote = [GTRemote remoteWithName:remoteName inRepository:fetchingRepo error:nil]; // Tested above

		BOOL result = [remote fetchWithError:&error credentials:nil progress:nil];
		expect(error).to.beNil();
		expect(result).to.beTruthy();
	});

	it(@"brings in new commits", ^{
		NSError *error = nil;

		// Create a new commit in the master repo
		NSString *testData = @"Test";
		NSString *fileName = @"test.txt";
		BOOL res = [testData writeToURL:[masterRepoURL URLByAppendingPathComponent:fileName] atomically:YES encoding:NSUTF8StringEncoding error:nil];
		expect(res).to.beTruthy();

		GTOID *testOID = [[masterRepo objectDatabaseWithError:nil] oidByInsertingString:testData objectType:GTObjectTypeBlob error:nil];
		GTTreeBuilder *treeBuilder = [[GTTreeBuilder alloc] initWithTree:nil error:nil];
		[treeBuilder addEntryWithOID:testOID filename:fileName filemode:GTFileModeBlob error:nil];

		GTTree *testTree = [treeBuilder writeTreeToRepository:masterRepo error:nil];

		// We need the parent commit to make the new one
		GTBranch *currentBranch = [masterRepo currentBranchWithError:nil];
		GTReference *currentReference = [currentBranch reference];

		GTEnumerator *commitEnum = [[GTEnumerator alloc] initWithRepository:masterRepo error:nil];
		[commitEnum pushSHA:[currentReference targetSHA] error:nil];
		GTCommit *parent = [commitEnum nextObject];

		GTCommit *testCommit = [GTCommit commitInRepository:masterRepo updateRefNamed:currentReference.name author:[masterRepo userSignatureForNow] committer:[masterRepo userSignatureForNow] message:@"Test commit" tree:testTree parents:@[parent] error:nil];
		expect(testCommit).notTo.beNil();

		// Now issue a fetch from the fetching repo
		GTRemote *remote = [GTRemote remoteWithName:remoteName inRepository:fetchingRepo error:nil];

		__block unsigned int receivedObjects = 0;
		res = [remote fetchWithError:&error credentials:nil progress:^(const git_transfer_progress *stats, BOOL *stop) {
			receivedObjects += stats->received_objects;
			NSLog(@"%d", receivedObjects);
		}];
		expect(error).to.beNil();
		expect(res).to.beTruthy();
		expect(receivedObjects).to.equal(10);

		GTCommit *fetchedCommit = [fetchingRepo lookupObjectByOID:testOID objectType:GTObjectTypeCommit error:&error];
		expect(error).to.beNil();
		expect(fetchedCommit).notTo.beNil();

		GTTreeEntry *entry = [[fetchedCommit tree] entryWithName:fileName];
		expect(entry).notTo.beNil();

		GTBlob *fileData = (GTBlob *)[entry toObjectAndReturnError:&error];
		expect(error).to.beNil();
		expect(fileData).notTo.beNil();
		expect(fileData.content).to.equal(testData);
	});
});

SpecEnd
