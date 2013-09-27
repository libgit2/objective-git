//
//  GTRepositorySpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2013-07-10.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

SpecBegin(GTRepositoryManipulation)

NSURL *repositoryURL = [NSURL fileURLWithPath:[[NSTemporaryDirectory() stringByAppendingPathComponent:@"Objective-Git"] stringByAppendingPathComponent:@"test-repo"] isDirectory:YES];
__block GTRepository *repository;

beforeAll(^{
	NSError *error = nil;
	repository = [GTRepository createRepositoryAtURL:repositoryURL error:&error];
	expect(repository).notTo.beNil();
	expect(error.description).to.beNil();
});

afterAll(^{
	NSError *error = nil;
	[NSFileManager.defaultManager removeItemAtURL:repositoryURL error:&error];
	expect(error.description).to.beNil();
});

describe(@"committing", ^{
	NSMutableArray *commits = [NSMutableArray array];

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

		GTCommit *initialCommit = [repository createCommitWithTree:tree message:@"Initial commit" parents:nil byUpdatingReferenceNamed:@"refs/heads/master" error:&error];
		expect(initialCommit).notTo.beNil();
		expect(error.description).to.beNil();
		[commits addObject:initialCommit];

		GTReference *ref = [repository headReferenceWithError:&error];
		expect(ref).notTo.beNil();
		expect(error.description).to.beNil();
	});

	it(@"can create more commits", ^{
		NSError *error = nil;
		GTCommit *initialCommit = commits.lastObject;
		GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:initialCommit.tree error:&error];
		expect(builder).toNot.beNil();

		[builder addEntryWithData:[@"Better test contents" dataUsingEncoding:NSUTF8StringEncoding] filename:@"Test file.txt" filemode:GTFileModeBlob error:&error];
		expect(error.description).to.beNil();

		GTTree *tree = [builder writeTreeToRepository:repository error:&error];
		expect(tree).notTo.beNil();
		expect(error.description).to.beNil();

		GTCommit *secondCommit = [repository createCommitWithTree:tree message:@"Initial commit" parents:@[ commits.lastObject ] byUpdatingReferenceNamed:@"refs/heads/master" error:&error];
		expect(secondCommit).notTo.beNil();
		expect(error.description).to.beNil();

		[commits addObject:secondCommit];
	});
});

SpecEnd
