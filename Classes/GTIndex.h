//
//  GTIndex.h
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

@class GTIndexEntry;
@class GTRepository;

@interface GTIndex : NSObject

// The repository in which the index resides. This may be nil if the index was
// created with -initWithFileURL:error:.
@property (nonatomic, readonly, strong) GTRepository *repository;

// The file URL for the index if it exists on disk.
@property (nonatomic, readonly, copy) NSURL *fileURL;

// The number of entries in the index.
@property (nonatomic, readonly) NSUInteger entryCount;

// The GTIndexEntries in the index.
@property (nonatomic, readonly, copy) NSArray *entries;

// Initializes the receiver with the index at the given file URL.
//
// fileURL - The file URL for the index on disk. Cannot be nil.
// error   - The error if one occurred.
//
// Returns the initialized object, or nil if an error occurred.
- (id)initWithFileURL:(NSURL *)fileURL error:(NSError **)error;

// Initializes the receiver with the given libgit2 index.
//
// index      - The libgit2 index from which the index should be created. Cannot
//              be NULL.
// repository - The repository in which the index resides. Cannot be nil.
//
// Returns the initialized object.
- (id)initWithGitIndex:(git_index *)index repository:(GTRepository *)repository;

// The underlying `git_index` object.
- (git_index *)git_index __attribute__((objc_returns_inner_pointer));

// Refresh the index from the datastore
//
// error - The error if one occurred.
//
// Returns whether the refresh was successful.
- (BOOL)refresh:(NSError **)error;

// Clear all the entries from the index. This happens in memory. Changes can be
// written to the datastore by calling -write:.
- (void)clear;

// Get the entry at the given index.
//
// index - The index of the entry to get. Must be within 0 and self.entryCount.
//
// Returns a new GTIndexEntry, or nil if an error occurred.
- (GTIndexEntry *)entryAtIndex:(NSUInteger)index;

// Get the entry with the given name.
- (GTIndexEntry *)entryWithName:(NSString *)name;

// Get the entry with the given name.
//
// name  - The name of the entry to get. Cannot be nil.
// error - The error if one occurred.
//
// Returns a new GTIndexEntry, or nil if an error occurred.
- (GTIndexEntry *)entryWithName:(NSString *)name error:(NSError **)error;

// Add an entry to the index.
//
// entry - The entry to add.
// error - The error if one occurred.
//
// Returns YES if successful, NO otherwise.
- (BOOL)addEntry:(GTIndexEntry *)entry error:(NSError **)error;

// Add an entry by path to the index.
// Will fail if the receiver's repository is nil.
//
// file  - The path (relative to the root of the repository) of the file to add.
// error - The error if one occurred.
//
// Returns YES if successful, NO otherwise.
- (BOOL)addFile:(NSString *)file error:(NSError **)error;

// Write the index to the repository.
// Will fail if the receiver's repository is nil.
//
// error - The error if one occurred.
//
// Returns YES if successful, NO otherwise.
- (BOOL)write:(NSError **)error;

@end
