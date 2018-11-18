//
//  GTWorktree.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 25/07/2017.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

#import "NSError+Git.h"
#import "GTWorktree.h"
#import "NSData+Git.h"

#import "git2/errors.h"
#import "git2/buffer.h"

NSString *GTWorktreeAddOptionsLocked = @"GTWorktreeAddOptionsLocked";

@interface GTWorktree ()
@property (nonatomic, assign, readonly) git_worktree *git_worktree;
@end

@implementation GTWorktree

+ (instancetype)addWorktreeWithName:(NSString *)name URL:(NSURL *)worktreeURL forRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	git_worktree *worktree;
	git_worktree_add_options git_options = GIT_WORKTREE_ADD_OPTIONS_INIT;

	if (options) {
		git_options.lock = [options[GTWorktreeAddOptionsLocked] boolValue];
	}

	int gitError = git_worktree_add(&worktree, repository.git_repository, name.UTF8String, worktreeURL.fileSystemRepresentation, &git_options);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to add worktree"];
		return nil;
	}

	return [[self alloc] initWithGitWorktree:worktree];
}

- (instancetype)initWithGitWorktree:(git_worktree *)worktree {
	self = [super init];
	if (!self) return nil;

	_git_worktree = worktree;

	return self;
}

- (void)dealloc {
	git_worktree_free(_git_worktree);
}

- (BOOL)isValid:(NSError **)error {
	int gitError = git_worktree_validate(self.git_worktree);
	if (gitError < 0) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to validate worktree"];
		return NO;
	}

	return YES;
}

- (BOOL)lockWithReason:(NSString *)reason error:(NSError **)error {
	int gitError = git_worktree_lock(self.git_worktree, reason.UTF8String);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to lock worktree"];
		return NO;
	}

	return YES;
}

- (BOOL)unlock:(BOOL *)wasLocked error:(NSError **)error {
	int gitError = git_worktree_unlock(self.git_worktree);
	if (gitError < 0) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to unlock worktree"];
		return NO;
	}

	if (wasLocked) {
		// unlock returns 1 if there was no lock.
		*wasLocked = (gitError == 0);
	}

	return YES;
}

- (BOOL)isLocked:(BOOL *)locked reason:(NSString **)reason error:(NSError **)error {
	git_buf reasonBuf = GIT_BUF_INIT_CONST("", 0);
	int gitError = git_worktree_is_locked(&reasonBuf, self.git_worktree);
	if (gitError < 0) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Failed to check lock state of worktree"];
		return NO;
	}

	if (locked) *locked = (gitError > 0);
	if (reason) {
		if (gitError > 0 && reasonBuf.size > 0) {
			*reason = [[NSString alloc] initWithData:[NSData git_dataWithBuffer:&reasonBuf]
											encoding:NSUTF8StringEncoding];
		} else {
			*reason = nil;
		}
	}

	return YES;
}

@end
