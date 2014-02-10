//
//  GTRepository+Blame.h
//  ObjectiveGitFramework
//
//  Created by Ezekiel Pierson on 2/5/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

// Enum for options passed to the dictionary in `-blameWithFile:inRepository:options:`
//
// For flag documentation see `blame.h`.
typedef enum {
	GTBlameOptionsNormal = GIT_BLAME_NORMAL,
} GTBlameOptions;

// A `NSNumber` wrapped `GTBlameOptions`. Flags are documented above.
extern NSString * const GTBlameOptionsFlags;

// A `GTOID` determining the newest commit to consider.
// Default is HEAD.
extern NSString * const GTBlameOptionsNewestCommitOID;

// A `GTOID` determining the oldest commit to consider.
// Default is the first commit without a parent.
extern NSString * const GTBlameOptionsOldestCommitOID;

// The first line in the file to blame. Default is 1.
extern NSString * const GTBlameOptionsFirstLine;

// The last line in the file to blame. Default is the last line.
extern NSString * const GTBlameOptionsLastLine;

@interface GTRepository (Blame)

// Create a blame for a file, with options.
//
// path       - Path for the file to examine. Can't be nil
// options    - A dictionary consiting of the above keys. May be nil.
// error      - Populated with an `NSError` object on error.
//
// Returns a new `GTBlame` object or nil if an error occurred.
- (GTBlame *)blameWithFile:(NSString *)path options:(NSDictionary *)options error:(NSError **)error;

@end
