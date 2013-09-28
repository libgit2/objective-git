//
//  GTRepository+Stashing.h
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-09-27.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

// Flags for -stashChangesWithMessage:flags:error:.
// Those can be ORed together. See git_stash_flags for additional information.
typedef enum {
	GTRepositoryStashFlagDefault = GIT_STASH_DEFAULT,
	GTRepositoryStashFlagKeepIndex = GIT_STASH_KEEP_INDEX,
	GTRepositoryStashFlagIncludeUntracked = GIT_STASH_INCLUDE_UNTRACKED,
	GTRepositoryStashFlagIncludeIgnored = GIT_STASH_INCLUDE_IGNORED
} GTRepositoryStashFlag;

@interface GTRepository (Stashing)

// Stash the repository's changes.
//
// message   - Message to be attributed to the item in the stash. This may be
//             nil.
// stashFlag - The flags of stash to be used.
// error     - If not NULL, set to any error that occurred.
//
// Returns a commit representing the stashed changes if successful, or nil
// otherwise.
- (GTCommit *)stashChangesWithMessage:(NSString *)message flags:(GTRepositoryStashFlag)flags error:(NSError **)error;

// Enumerate over all the stashes in the repository, from most recent to oldest.
//
// block - A block to execute for each stash found. `index` will be the zero-based
//         stash index (where 0 is the most recent stash). Setting `stop` to YES
//         will cause enumeration to stop after the block returns.
- (void)enumerateStashesUsingBlock:(void (^)(NSUInteger index, NSString *message, GTOID *oid, BOOL *stop))block;

// Drop a stash from the repository's list of stashes.
//
// index - The index of the stash to drop, where 0 is the most recent stash.
// error - If not NULL, set to any error that occurs.
//
// Returns YES if the stash was successfully dropped, NO otherwise
- (BOOL)dropStashAtIndex:(NSUInteger)index error:(NSError **)error;

@end
