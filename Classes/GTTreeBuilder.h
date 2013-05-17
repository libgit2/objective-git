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

@class GTTree;
@class GTTreeEntry;
@class GTRepository;
@interface GTTreeBuilder : NSObject

// the underlaying git_treebuilder
@property (nonatomic, readonly) git_treebuilder *git_treebuilder;

- (id)initWithTree:(GTTree *)treeOrNil error:(NSError **)error;

// Clear all the entires in the builder
- (void)clear;

// Get the number of entries listed in a treebuilder
- (NSUInteger)entryCount;

// Filter the entries in the tree
//
// The filter callback will be called for each entry in the tree with a pointer
// to the entry and the provided payload; if the callback returns non-zero, the
// entry will be filtered (removed from the builder).
//
- (void)filter:(git_treebuilder_filter_cb)filterCallback context:(void *)context;

// Get an entry from the builder from its filename
- (GTTreeEntry *)entryWithName:(NSString *)filename;

// Add or update an entry to the builder
//
// Insert a new entry for filename in the builder with the given attributes.
//
// If an entry named filename already exists, its attributes will be updated
// with the given ones.
//
// No attempt is being made to ensure that the provided oid points to an
// existing git object in the object database, nor that the attributes make
// sense regarding the type of the pointed at object.
- (GTTreeEntry *)addEntryWithSha1:(NSString *)sha filename:(NSString *)filename filemode:(git_filemode_t)filemode error:(NSError **)error;

// Remove an entry from the builder by its filename
- (BOOL)removeEntryWithFilename:(NSString *)filename error:(NSError **)error;

// Write the contents of the tree builder as a tree object
- (GTTree *)writeTreeToRepository:(GTRepository *)repository error:(NSError **)error;
@end
