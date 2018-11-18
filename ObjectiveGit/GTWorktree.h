//
//  GTWorktree.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 25/07/2017.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GTRepository.h"

#import "git2/worktree.h"

NS_ASSUME_NONNULL_BEGIN

/// Add a worktree and keep it locked
/// A boolean, defaults to NO.
extern NSString *GTWorktreeAddOptionsLocked;

@interface GTWorktree : NSObject

/// Add a new worktree to a repository.
///
/// @param name The name of the worktree.
/// @param worktreeURL The location of the worktree.
/// @param repository The repository the worktree should be added to.
/// @param options The options to use when adding the worktree.
///
/// @return the newly created worktree object.
+ (instancetype _Nullable)addWorktreeWithName:(NSString *)name URL:(NSURL *)worktreeURL forRepository:(GTRepository *)repository options:(NSDictionary * _Nullable)options error:(NSError **)error;

/// Initialize a worktree from a git_worktree.
- (instancetype _Nullable)initWithGitWorktree:(git_worktree *)worktree;

/// The underlying `git_worktree` object.
- (git_worktree *)git_worktree __attribute__((objc_returns_inner_pointer));

/// Check the worktree validity
///
/// @param error An explanation if the worktree is not valid. nil otherwise
///
/// @return YES if the worktree is valid, NO otherwise (and error will be set).
- (BOOL)isValid:(NSError **)error;

/// Lock the worktree.
///
/// This will prevent the worktree from being prunable.
///
/// @param reason An optional reason for the lock.
/// @param error The error if the worktree couldn't be locked.
///
/// @return YES if the lock was successful, NO otherwise (and error will be set).
- (BOOL)lockWithReason:(NSString * _Nullable)reason error:(NSError **)error;

/// Unlock a worktree.
///
/// @param wasLocked On return, NO if the worktree wasn't locked, YES otherwise.
/// @param error The error if the worktree couldn't be unlocked.
///
/// @return YES if the unlock succeeded, NO otherwise (and error will be set).
- (BOOL)unlock:(BOOL * _Nullable)wasLocked error:(NSError **)error;

/// Check a worktree's lock state.
///
/// @param locked On return, YES if the worktree is locked, NO otherwise.
/// @param reason On return, the lock reason, if the worktree is locked. nil otherwise.
/// @param error The error if the lock state couldn't be determined.
///
/// @return YES if the check succeeded, NO otherwise (and error will be set).
- (BOOL)isLocked:(BOOL * _Nullable)locked reason:(NSString * _Nullable __autoreleasing * _Nullable)reason error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
