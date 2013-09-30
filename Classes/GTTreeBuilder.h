//
//  GTTreeBuilder.h
//  ObjectiveGitFramework
//
//  Created by Johnnie Walker on 17/05/2013.
//
//  The MIT License
//
//  Copyright (c) 2013 Johnnie Walker
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

#import <Foundation/Foundation.h>
#include "git2.h"

// The mode of an index or tree entry.
typedef enum {
	GTFileModeNew = GIT_FILEMODE_NEW,
	GTFileModeTree = GIT_FILEMODE_TREE,
	GTFileModeBlob = GIT_FILEMODE_BLOB,
	GTFileModeBlobExecutable = GIT_FILEMODE_BLOB_EXECUTABLE,
	GTFileModeLink = GIT_FILEMODE_LINK,
	GTFileModeCommit = GIT_FILEMODE_COMMIT
} GTFileMode;

@class GTTree;
@class GTTreeEntry;
@class GTRepository;
@class GTOID;

// A tree builder is used to create or modify trees in memory and write them as
// tree objects to a repository.
@interface GTTreeBuilder : NSObject

// Get the number of entries listed in a treebuilder.
@property (nonatomic, readonly) NSUInteger entryCount;

// Initializes the receiver, optionally from an existing tree.
//
// treeOrNil - Source tree (or nil)
// error     - The error if one occurred.
//
// Returns the initialized object, or nil if an error occurred.
- (id)initWithTree:(GTTree *)treeOrNil error:(NSError **)error;

// The underlying `git_treebuilder` object.
- (git_treebuilder *)git_treebuilder __attribute__((objc_returns_inner_pointer));

// Clear all the entires in the builder.
- (void)clear;

// Filter the entries in the tree.
//
// filterBlock - A block which returns YES for entries which should be filtered
//               from the index.
- (void)filter:(BOOL (^)(const git_tree_entry *entry))filterBlock;

// Get an entry from the builder from its file name.
//
// fileName - File name for the object in the index. Cannot be nil.
//
// Returns the matching entry or nil if it doesn't exist.
- (GTTreeEntry *)entryWithFileName:(NSString *)fileName;

// Adds or updates the entry for the file name with the given data. When the
// tree is written, a blob will be inserted into the object database containing
// `data`.
//
// data     - The data for the entry. Cannot be nil.
// fileName - The file name for the object. Cannot be nil.
// fileMode - The file mode for the object.
// error    - The error if one occurred.
//
// Returns the added entry, or nil if an error occurred
- (GTTreeEntry *)addEntryWithData:(NSData *)data fileName:(NSString *)fileName fileMode:(GTFileMode)fileMode error:(NSError **)error;

// Add or update an entry to the builder.
//
// oid      - The OID of a git object aleady stored in the repository.
// fileName - File name for the object in the index. Cannot be nil.
// fileMode - File mode for the object in the index.
// error    - The error if one occurred.
//
// If an entry named `filename` already exists, its attributes will be updated
// with the given ones.
//
// No attempt is made to ensure that the provided oid points to an existing git
// object in the object database, nor that the attributes make sense regarding
// the type of the pointed at object.
//
// Returns the added entry, or nil if an error occurred.
- (GTTreeEntry *)addEntryWithOID:(GTOID *)oid fileName:(NSString *)fileName fileMode:(GTFileMode)fileMode error:(NSError **)error;

// Remove an entry from the builder by its file name.
//
// fileName - File name for the object in the tree.
// error    - The error if one occurred.
//
// Returns YES if the entry was removed, or NO if an error occurred.
- (BOOL)removeEntryWithFileName:(NSString *)fileName error:(NSError **)error;

// Write the contents of the tree builder as a tree object.
//
// repository - Repository in which to write the tree.
// error      - The error if one occurred.
//
// Returns the written tree, or nil if an error occurred.
- (GTTree *)writeTreeToRepository:(GTRepository *)repository error:(NSError **)error;

@end
