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
@class GTTree;

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

// Whether the index contains conflicted files.
@property (nonatomic, readonly) BOOL hasConflicts;

// Creates an in-memory index.
//
// repository - A repository that paths should be relative to. Cannot be nil.
// error      - If not NULL, set to any error that occurs.
//
// Returns the newly created index, or nil if an error occurred.
+ (instancetype)inMemoryIndexWithRepository:(GTRepository *)repository error:(NSError **)error;

// Loads the index at the given file URL.
//
// fileURL    - The file URL for the index on disk. Cannot be nil.
// repository - A repository that paths should be relative to. Cannot be nil.
// error      - If not NULL, set to any error that occurs.
//
// Returns the loaded index, or nil if an error occurred.
+ (instancetype)indexWithFileURL:(NSURL *)fileURL repository:(GTRepository *)repository error:(NSError **)error;

// Initializes the receiver with the given libgit2 index.
//
// index      - The libgit2 index from which the index should be created. Cannot
//              be NULL.
// repository - The repository in which the index resides. Cannot be nil.
//
// Returns the initialized index.
- (instancetype)initWithGitIndex:(git_index *)index repository:(GTRepository *)repository;

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
// Note that this *cannot* add submodules. See -[GTSubmodule addToIndex:].
//
// entry - The entry to add.
// error - The error if one occurred.
//
// Returns YES if successful, NO otherwise.
- (BOOL)addEntry:(GTIndexEntry *)entry error:(NSError **)error;

// Add an entry (by relative path) to the index.
// Will fail if the receiver's repository is nil.
//
// Note that this *cannot* add submodules. See -[GTSubmodule addToIndex:].
//
// file  - The path (relative to the root of the repository) of the file to add.
// error - The error if one occurred.
//
// Returns YES if successful, NO otherwise.
- (BOOL)addFile:(NSString *)file error:(NSError **)error;

// Reads the contents of the given tree into the index. 
//
// tree  - The tree to add to the index. This must not be nil.
// error - If not NULL, set to any error that occurs.
//
// Returns whether reading the tree was successful.
- (BOOL)addContentsOfTree:(GTTree *)tree error:(NSError **)error;

// Remove an entry (by relative path) from the index.
// Will fail if the receiver's repository is nil.
//
// file  - The path (relative to the root of the repository) of the file to
//         remove.
// error - The error, if one occurred.
//
// Returns YES if successful, NO otherwise.
- (BOOL)removeFile:(NSString *)file error:(NSError **)error;

// Write the index to the repository.
// Will fail if the receiver's repository is nil.
//
// error - The error if one occurred.
//
// Returns YES if successful, NO otherwise.
- (BOOL)write:(NSError **)error;

// Write the index to the repository as a tree.
// Will fail if the receiver's repository is nil.
//
// error - The error if one occurred.
//
// Returns a new GTTree, or nil if an error occurred.
- (GTTree *)writeTree:(NSError **)error;

// Write the index to the given repository as a tree.
// Will fail if the receiver's index has conflicts.
//
// repository - The repository to write the tree to. Can't be nil.
// error      - The error if one occurred.
//
// Returns a new GTTree or nil if an error occurred.
- (GTTree *)writeTreeToRepository:(GTRepository *)repository error:(NSError **)error;

// Enumerate through any conflicts in the index, running the provided block each
// time.
//
// error - Optionally set in the event of failure.
// block - A block to be run on each conflicted entry. Passed in are index
//         entries which represent the common ancestor as well as our and their
//         side of the conflict. If the block sets `stop` to YES then the
//         iteration will cease once the current block execution has finished.
//         Must not be nil.
//
// Returns `YES` in the event of successful enumeration or no conflicts in the
// index, `NO` in case of error.
- (BOOL)enumerateConflictedFilesWithError:(NSError **)error usingBlock:(void (^)(GTIndexEntry *ancestor, GTIndexEntry *ours, GTIndexEntry *theirs, BOOL *stop))block;

// Update all index entries to match the working directory.
// This method will immediately fail if the index's repo is bare.
//
// pathspecs - An `NSString` array of path patterns. (E.g: *.c)
//             If nil is passed in, all index entries will be updated.
// block     - A block run each time a pathspec is matched; before the index is updated.
//             The `matchedPathspec` parameter is a string indicating what the pathspec (from `pathspecs`) matched.
//             If you pass in NULL in to the `pathspecs` parameter this parameter will be empty.
//             The `path` parameter is a repository relative path to the file about to be updated.
//             The `stop` parameter can be set to `YES` to abort the operation.
//             Return `YES` to update the given path, or `NO` to skip it. May be nil.
// error     - When something goes wrong, this parameter is set. Optional.
//
// Returns `YES` in the event that everything has gone smoothly. Otherwise, `NO`.
- (BOOL)updatePathspecs:(NSArray *)pathspecs error:(NSError **)error passingTest:(BOOL (^)(NSString *matchedPathspec, NSString *path, BOOL *stop))block;

@end
