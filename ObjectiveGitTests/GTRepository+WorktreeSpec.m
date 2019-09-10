//
//  GTRepository+WorktreeSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2018-08-16.
//  Copyright (c) 2018 GitHub, Inc. All rights reserved.
//

@import ObjectiveGit;
@import Nimble;
@import Quick;

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTRepositoryWorktreeSpec)

__block GTRepository *repo;

__block GTWorktree *worktree;
beforeEach(^{
	repo = self.bareFixtureRepository;
	expect(repo).notTo(beNil());

	NSURL *worktreeURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"test-worktree"];

	NSError *error = nil;
	worktree = [GTWorktree addWorktreeWithName:@"test" URL:worktreeURL forRepository:repo options:nil error:&error];
	expect(worktree).notTo(beNil());
	expect(error).to(beNil());
});

describe(@"-isWorktree", ^{
	expect(repo.isWorktree).to(beFalse());
});

describe(@"-worktreeNamesWithError:", ^{
	it(@"returns the list of worktrees", ^{
		NSError *error = nil;
		NSArray *worktreeNames = [repo worktreeNamesWithError:&error];
		expect(worktreeNames).to(contain(@"test"));
	});
});

describe(@"-lookupWorktreeWithName:", ^{
	it(@"returns an existing worktree", ^{
		NSError *error = nil;

		GTWorktree *worktree2 = [repo lookupWorktreeWithName:@"test" error:&error];
		expect(worktree2).notTo(beNil());
		expect(error).to(beNil());
	});

	it(@"fails on non-existent worktrees", ^{
		NSError *error = nil;

		GTWorktree *worktree2 = [repo lookupWorktreeWithName:@"blob" error:&error];
		expect(worktree2).to(beNil());
		expect(error).notTo(beNil());
		expect(error.code).to(equal(-1));
		expect(error.localizedDescription).to(equal(@"Failed to lookup worktree"));
	});
});

describe(@"+openWorktree", ^{
	it(@"won't return a worktree from a real repository", ^{
		NSError *error = nil;

		GTWorktree *repoWorktree = [repo openWorktree:&error];
		expect(repoWorktree).to(beNil());
		expect(error).notTo(beNil());
		expect(error.code).to(equal(-1));
		expect(error.localizedDescription).to(equal(@"Failed to open worktree"));
	});

	it(@"can return a worktree from a worktree's repository", ^{
		NSError *error = nil;

		GTRepository *repoWt = [GTRepository repositoryWithWorktree:worktree error:&error];
		expect(repoWt).notTo(beNil());
		expect(repoWt.isWorktree).to(beTrue());

		GTWorktree *worktreeRepoWt = [repoWt openWorktree:&error];
		expect(worktreeRepoWt).notTo(beNil());
		expect(error).to(beNil());

	});
});

describe(@"+repositoryWithWorktree:", ^{
	it(@"can open a repository from a worktree", ^{
		NSError *error = nil;

		GTRepository *repo2 = [GTRepository repositoryWithWorktree:worktree error:&error];
		expect(repo2).notTo(beNil());
		expect(error).to(beNil());

		expect(repo.isWorktree).to(beFalse());
	});
});

fdescribe(@"with a worktree repository", ^{
	__block GTRepository *worktreeRepo;
	beforeEach(^{
		NSError *error = nil;

		worktreeRepo = [GTRepository repositoryWithWorktree:worktree error:&error];
		expect(worktreeRepo).notTo(beNil());
		expect(error).to(beNil());
	});

	describe(@"-fileURL", ^{
		it(@"returns an absolute url", ^{
			NSURL *url = worktreeRepo.fileURL;
			expect(url).notTo(beNil());
			expect([url.path substringToIndex:1]).to(equal(@"/"));
		});
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
