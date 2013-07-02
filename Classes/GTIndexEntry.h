//
//  GTIndexEntry.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#include "git2.h"

typedef enum {
	GTIndexEntryStatusUpdated = 0,
	GTIndexEntryStatusConflicted,
	GTIndexEntryStatusAdded,
	GTIndexEntryStatusRemoved,
	GTIndexEntryStatusUpToDate,
} GTIndexEntryStatus;

@interface GTIndexEntry : NSObject

// The repository-relative path for the entry.
@property (nonatomic, readonly, copy) NSString *path;

// Has the entry been staged?
@property (nonatomic, getter = isStaged, readonly) BOOL staged;

// What is the entry's status?
@property (nonatomic, readonly) GTIndexEntryStatus status;

// Initializes the receiver with the given libgit2 index entry.
//
// entry - The libgit2 index entry. Cannot be NULL.
//
// Returns the initialized object.
- (id)initWithGitIndexEntry:(const git_index_entry *)entry;

// The underlying `git_index_entry` object.
- (const git_index_entry *)git_index_entry __attribute__((objc_returns_inner_pointer));

@end
