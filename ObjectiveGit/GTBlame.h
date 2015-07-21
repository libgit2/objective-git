//
//  GTBlame.h
//  ObjectiveGitFramework
//
//  Created by David Catmull on 11/6/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/blame.h"

@class GTBlameHunk;
@class GTRepository;

NS_ASSUME_NONNULL_BEGIN

/// A `GTBlame` provides authorship info, through `GTBlameHunk` for each line of a file. Analogous to `git_blame` in libgit2.
@interface GTBlame : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer.
///
/// blame - A git_blame to wrap. May not be NULL.
///
/// Returns a blame, or nil if initialization failed.
- (nullable instancetype)initWithGitBlame:(git_blame *)blame NS_DESIGNATED_INITIALIZER;

/// Get all the hunks in the blame. A convenience wrapper around `enumerateHunksUsingBlock:`
@property (nonatomic, strong, readonly) NSArray *hunks;

/// The number of hunks in the blame.
@property (nonatomic, readonly) NSUInteger hunkCount;

/// Get the hunk at the specified index.
///
/// index - The index to retrieve the hunk from.
///
/// Returns a `GTBlameHunk` or nil if an error occurred.
- (nullable GTBlameHunk *)hunkAtIndex:(NSUInteger)index;

/// Enumerate the hunks in the blame.
///
/// block - A block invoked for every hunk in the blame.
///         Setting stop to `YES` instantly stops the enumeration.
///         May not be NULL.
///
- (void)enumerateHunksUsingBlock:(void (^)(GTBlameHunk *hunk, NSUInteger index, BOOL *stop))block;

/// Get the hunk that relates to the given line number in the newest commit.
///
/// lineNumber - The (1 based) line number to find a hunk for.
///
/// Returns a `GTBlameHunk` or nil if an error occurred.
- (nullable GTBlameHunk *)hunkAtLineNumber:(NSUInteger)lineNumber;

/// The underlying `git_blame` object.
- (git_blame *)git_blame __attribute__((objc_returns_inner_pointer));

@end

NS_ASSUME_NONNULL_END
