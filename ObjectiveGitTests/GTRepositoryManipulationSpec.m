//
//  GTRepositorySpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2013-07-10.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

SpecBegin(GTRepositoryManipulation)

NSURL *repositoryURL = [NSURL fileURLWithPath:@"/tmp/Objective-Git/test-repo" isDirectory:YES];
__block GTRepository *repository;

beforeAll(^{
	NSError *error = nil;
	repository = [GTRepository createRepositoryAtURL:repositoryURL error:&error];
	expect(repository).notTo.beNil();
	expect(error.description).to.beNil();
});

afterAll(^{
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtURL:repositoryURL error:&error];
	expect(error.description).to.beNil();
});

describe(@"GTRepository", ^{
	it(@"can create initial commits", ^{
		NSError *error = nil;
		GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
		expect(builder).toNot.beNil();

		[builder addEntryWithData:[@"Another file contents" dataUsingEncoding:NSUTF8StringEncoding] filename:@"Test file 2.txt" filemode:GTFileModeBlob error:&error];
		expect(error.description).to.beNil();

		GTTree *subtree = [builder writeTreeToRepository:repository error:&error];
		expect(subtree).notTo.beNil();
		expect(error.description).to.beNil();

		[builder clear];

		[builder addEntryWithData:[@"Test contents" dataUsingEncoding:NSUTF8StringEncoding] filename:@"Test file.txt" filemode:GTFileModeBlob error:&error];
		expect(error.description).to.beNil();

		[builder addEntryWithOID:subtree.OID filename:@"subdir" filemode:GTFileModeTree error:&error];
		expect(error.description).to.beNil();

		GTTree *tree = [builder writeTreeToRepository:repository error:&error];
		expect(tree).notTo.beNil();
		expect(error.description).to.beNil();

		GTCommit *initialCommit = [repository commitWithTree:tree message:@"Initial commit" parents:nil byUpdatingReferenceNamed:@"refs/heads/master" error:&error];
		expect(initialCommit).notTo.beNil();
		expect(error.description).to.beNil();

		GTReference *ref = [repository headReferenceWithError:&error];
		expect(ref).notTo.beNil();
		expect(error.description).to.beNil();
	});
});

//describe(@"-preparedMessage", ^{
//	it(@"should return nil by default", ^{
//		__block NSError *error = nil;
//		expect([repository preparedMessageWithError:&error]).to.beNil();
//		expect(error).to.beNil();
//	});
//
//	it(@"should return the contents of MERGE_MSG", ^{
//		NSString *message = @"Commit summary\n\ndescription";
//		expect([message writeToURL:[repository.gitDirectoryURL URLByAppendingPathComponent:@"MERGE_MSG"] atomically:YES encoding:NSUTF8StringEncoding error:NULL]).to.beTruthy();
//
//		__block NSError *error = nil;
//		expect([repository preparedMessageWithError:&error]).to.equal(message);
//		expect(error).to.beNil();
//	});
//});
//
//describe(@"-mergeBaseBetweenFirstOID:secondOID:error:", ^{
//	it(@"should find the merge base between two branches", ^{
//		NSError *error = nil;
//		GTBranch *masterBranch = [[GTBranch alloc] initWithName:@"refs/heads/master" repository:repository error:&error];
//		expect(masterBranch).notTo.beNil();
//		expect(error).to.beNil();
//
//		GTBranch *otherBranch = [[GTBranch alloc] initWithName:@"refs/heads/other-branch" repository:repository error:&error];
//		expect(otherBranch).notTo.beNil();
//		expect(error).to.beNil();
//
//		GTCommit *mergeBase = [repository mergeBaseBetweenFirstOID:masterBranch.reference.OID secondOID:otherBranch.reference.OID error:&error];
//		expect(mergeBase).notTo.beNil();
//		expect(mergeBase.sha).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
//	});
//});

SpecEnd
