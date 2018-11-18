//
//  GTWorktreeSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2018-08-16.
//  Copyright (c) 2018 GitHub, Inc. All rights reserved.
//

@import ObjectiveGit;
@import Nimble;
@import Quick;

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTWorktreeSpec)

__block GTRepository *repo;

beforeEach(^{
	repo = self.bareFixtureRepository;
	expect(repo).notTo(beNil());
});

describe(@"GTWorktree", ^{
	describe(@"with no existing worktree", ^{
		describe(@"+addWorktreeWithName:", ^{
			it(@"can add a worktree to a repository", ^{
				NSURL *worktreeURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"test-worktree"];

				NSError *error = nil;
				GTWorktree *worktree = [GTWorktree addWorktreeWithName:@"test" URL:worktreeURL forRepository:repo options:nil error:&error];
				expect(worktree).notTo(beNil());
				expect(error).to(beNil());

				BOOL locked;
				NSString *reason;
				BOOL success = [worktree isLocked:&locked reason:&reason error:&error];
				expect(success).to(beTrue());
				expect(locked).to(beFalse());
				expect(reason).to(beNil());
				expect(error).to(beNil());
			});

			it(@"can add a worktree to a repository, keeping it locked", ^{
				NSURL *worktreeURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"test-worktree"];

				NSError *error = nil;
				GTWorktree *worktree = [GTWorktree addWorktreeWithName:@"test"
																   URL:worktreeURL
														 forRepository:repo
															   options:@{
																		 GTWorktreeAddOptionsLocked: @(YES),
																		 }
																 error:&error];
				expect(worktree).notTo(beNil());
				expect(error).to(beNil());

				BOOL locked;
				NSString *reason;
				BOOL success = [worktree isLocked:&locked reason:&reason error:&error];
				expect(success).to(beTrue());
				expect(locked).to(beTrue());
				expect(reason).to(beNil());
				expect(error).to(beNil());
			});
		});
	});

	describe(@"with an existing worktree", ^{
		__block GTWorktree *worktree;
		beforeEach(^{
			NSURL *worktreeURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"test-worktree"];

			NSError *error = nil;
			worktree = [GTWorktree addWorktreeWithName:@"test" URL:worktreeURL forRepository:repo options:nil error:&error];
			expect(worktree).notTo(beNil());
			expect(error).to(beNil());
		});

		describe(@"-lockWithReason:", ^{
			afterEach(^{
				[worktree unlock:NULL error:NULL];
			});

			it(@"can lock with no reason", ^{
				NSError *error = nil;

				BOOL success = [worktree lockWithReason:nil error:&error];
				expect(success).to(beTrue());
				expect(error).to(beNil());

				BOOL isLocked;
				NSString *reason;
				success = [worktree isLocked:&isLocked reason:&reason error:&error];
				expect(success).to(beTrue());
				expect(isLocked).to(beTrue());
				expect(reason).to(beNil());
				expect(error).to(beNil());
			});

			it(@"can lock with a reason", ^{
				NSError *error = nil;

				BOOL success = [worktree lockWithReason:@"a bad reason" error:&error];
				expect(success).to(beTrue());
				expect(error).to(beNil());

				BOOL isLocked;
				NSString *reason;
				success = [worktree isLocked:&isLocked reason:&reason error:&error];
				expect(success).to(beTrue());
				expect(isLocked).to(beTrue());
				expect(reason).to(equal(@"a bad reason"));
				expect(error).to(beNil());
			});
		});

		describe(@"-unlock:", ^{
			it(@"knows about non-locked worktrees", ^{
				NSError *error = nil;

				BOOL wasLocked = NO;
				BOOL success = [worktree unlock:&wasLocked error:&error];
				expect(success).to(beTrue());
				expect(wasLocked).to(beTrue()); // https://github.com/libgit2/libgit2/pull/4769
				expect(error).to(beNil());
			});

			it(@"can unlock locked worktrees", ^{
				NSError *error = nil;

				BOOL success = [worktree lockWithReason:NULL error:NULL];
				expect(success).to(beTrue());

				BOOL wasLocked = NO;
				success = [worktree unlock:&wasLocked error:&error];
				expect(success).to(beTrue());
				expect(wasLocked).to(beTrue());
				expect(error).to(beNil());
			});
		});
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
