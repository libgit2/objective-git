//
//  GTRemoteSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2013-09-06
//
//  The MIT License
//
//  Copyright (c) 2013 Etienne Samson
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
	expect(masterRepo).notTo.beNil();

	NSURL *masterRepoURL = [masterRepo gitDirectoryURL];
	NSURL *fixturesURL = [masterRepoURL URLByDeletingLastPathComponent];
	fetchingRepoURL = [fixturesURL URLByAppendingPathComponent:@"fetchrepo"];

	// Make sure there's no leftover
	[[NSFileManager defaultManager] removeItemAtURL:fetchingRepoURL error:nil];

	NSError *error = nil;
	fetchingRepo = [GTRepository cloneFromURL:masterRepoURL toWorkingDirectory:fetchingRepoURL barely:NO withCheckout:YES error:&error transferProgressBlock:nil checkoutProgressBlock:nil];
	expect(fetchingRepo).notTo.beNil();
	expect(error.localizedDescription).to.beNil();

	remoteNames = [fetchingRepo remoteNamesWithError:&error];
	expect(error.localizedDescription).to.beNil();
	expect(remoteNames.count).to.beGreaterThanOrEqualTo(@(1));

	remoteName = [remoteNames objectAtIndex:0];
	expect(remoteName).notTo.beNil();
});

afterEach(^{
	[[NSFileManager defaultManager] removeItemAtURL:fetchingRepoURL error:nil];
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
