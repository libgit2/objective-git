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

// Enum for options passed to `-blameWithFile:inRepository:options:`
//
// For flag documentation see `blame.h`.
typedef enum {
	GTBlameOptionsNormal = GIT_BLAME_NORMAL,
	GTBlameOptionsTrackCopiesSameFile = GIT_BLAME_TRACK_COPIES_SAME_FILE,
	GTBlameOptionsTrackCopiesSameCommitMoves = GIT_BLAME_TRACK_COPIES_SAME_COMMIT_MOVES,
	GTBlameOptionsTrackCopiesSameCommitCopies = GIT_BLAME_TRACK_COPIES_SAME_COMMIT_COPIES,
	GTBlameOptionsTrackCopiesAnyCommitCopies = GIT_BLAME_TRACK_COPIES_ANY_COMMIT_COPIES,
} GTBlameOptionsFlags;

@interface GTBlame : NSObject

// Create a blame for a file, with options.
//
// path				- Path for the file to examine.
// repository - Repository containing the file.
// options		- Option flags, such as for tracking copies.
+ (GTBlame *)blameWithFile:(NSString *)path inRepository:(GTRepository *)repository options:(GTBlameOptionsFlags)options;

// Create a blame with the default options.
//
// path				- Path for the file to examine.
// repository - Repository containing the file.
+ (GTBlame *)blameWithFile:(NSString *)path inRepository:(GTRepository *)repository;

// Designated initializer.
- (instancetype)initWithGitBlame:(git_blame *)blame;

- (GTBlameHunk *)hunkAtIndex:(NSUInteger)index;

@property (nonatomic, readonly) NSUInteger hunkCount;

@end

