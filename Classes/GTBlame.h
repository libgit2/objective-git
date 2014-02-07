//
//  GTBlame.h
//  ObjectiveGitFramework
//
//  Created by David Catmull on 11/6/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2.h"

@class GTBlameHunk;
@class GTRepository;

// A `GTBlame` provides authorship info, through `GTBlameHunk` for each line of a file.
@interface GTBlame : NSObject

// Designated initializer.
- (instancetype)initWithGitBlame:(git_blame *)blame;

// Get all the hunks in the blame. A convenience wrapper around `enumerateHunksUsingBlock:`
@property (nonatomic, strong, readonly) NSArray *hunks;

// The number of hunks in the blame.
@property (nonatomic, readonly) NSUInteger hunkCount;

// Get the hunk at the specified index.
//
// index - The index to retrieve the hunk from.
//
// Returns a `GTBlameHunk` or nil if an error occurred.
- (GTBlameHunk *)hunkAtIndex:(NSUInteger)index;

// Enumerate the hunks in the blame.
//
// block - A block invoked for every hunk in the blame.
//         Setting stop to `YES` instantly stops the enumeration.
//
- (void)enumerateHunksUsingBlock:(void (^)(GTBlameHunk *hunk, NSUInteger index, BOOL *stop))block;

// Get the hunk that relates to the given line number in the newest commit.
//
// lineNumber - The (1 based) line number to find a hunk for.
//
// Returns a `GTBlameHunk` or nil if an error occurred.
- (GTBlameHunk *)hunkAtLineNumber:(NSUInteger)lineNumber;

// The underlying `git_blame` object.
- (git_blame *)git_blame __attribute__((objc_returns_inner_pointer));

@end

