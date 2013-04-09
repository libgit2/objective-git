//
//  GTReflog.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@class GTSignature;
@class GTReflogEntry;

// A reflog for a reference. Reflogs should not be created manually. Use
// -[GTReference reflog] to get the reflog for a reference.
@interface GTReflog : NSObject

// The number of reflog entries.
@property (nonatomic, readonly, assign) NSUInteger entryCount;

// Writes a new entry to the reflog.
//
// committer - The committer for the reflog entry. Cannot be nil.
// message   - The message to associate with the entry. May be nil.
// error     - The error if one occurred.
//
// Returns whether the entry was successfully written.
- (BOOL)writeEntryWithCommitter:(GTSignature *)committer message:(NSString *)message error:(NSError **)error;

// Get the reflog entry at the given index.
//
// index - The reflog entry to get. 0 is the most recent entry. If it is greater
//         than `entryCount`, it will assert.
//
// Returns the entry at that index.
- (GTReflogEntry *)entryAtIndex:(NSUInteger)index;

@end
