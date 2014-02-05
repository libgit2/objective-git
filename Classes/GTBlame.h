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

// Enum for options passed to the dictionary in `-blameWithFile:inRepository:options:`
//
// For flag documentation see `blame.h`.
typedef enum {
	GTBlameOptionsNormal = GIT_BLAME_NORMAL,
	GTBlameOptionsTrackCopiesSameFile = GIT_BLAME_TRACK_COPIES_SAME_FILE,
	GTBlameOptionsTrackCopiesSameCommitMoves = GIT_BLAME_TRACK_COPIES_SAME_COMMIT_MOVES,
	GTBlameOptionsTrackCopiesSameCommitCopies = GIT_BLAME_TRACK_COPIES_SAME_COMMIT_COPIES,
	GTBlameOptionsTrackCopiesAnyCommitCopies = GIT_BLAME_TRACK_COPIES_ANY_COMMIT_COPIES,
} GTBlameOptions;

// A `NSNumber` wrapped `GTBlameOptions`. Flags are documented above.
extern NSString *const GTBlameOptionsFlags;

// A `NSNumber` determining the number of characters that triggers a copy/move.
// Only works with `GTBlameOptionsTrackCopies*`. Default is 20;
extern NSString *const GTBlameOptionsMinimumMatchCharacters;

// A `GTOID` determining the newest commit to consider.
// Default is HEAD.
extern NSString *const GTBlameOptionsNewestCommitOID;

// A `GTOID` determining the oldest commit to consider.
// Default is the first commit with a `NULL` parent.
extern NSString *const GTBlameOptionsOldestCommitOID;

// The first line in the file to blame. Default is 1.
extern NSString *const GTBlameOptionsFirstLine;

// The last line in the file to blame. Default is the last line.
extern NSString *const GTBlameOptionsLastLine;

@interface GTBlame : NSObject

// Create a blame for a file, with options.
//
// path       - Path for the file to examine.
// repository - Repository containing the file.
// options    - A dictionary consiting of the above keys.
// error      - Populated with an `NSError` object on error.
//
// Returns a new `GTBlame` object or nil if an error occurred.
+ (GTBlame *)blameWithFile:(NSString *)path inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error;

// Create a blame with the default options.
//
// path       - Path for the file to examine.
// repository - Repository containing the file.
// error      - Populated with an `NSError` object on error.
//
// Returns a new `GTBlame` object or nil if an error occurred.
+ (GTBlame *)blameWithFile:(NSString *)path inRepository:(GTRepository *)repository error:(NSError **)error;

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

