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


@interface GTIndex : NSObject {}

@property (nonatomic, assign) git_index *git_index;
@property (nonatomic, copy) NSURL *fileURL;
@property (nonatomic, readonly) NSUInteger entryCount;
@property (nonatomic, readonly) NSArray *entries;

// Convenience initializers
- (id)initWithFileURL:(NSURL *)localFileUrl error:(NSError **)error;
+ (id)indexWithFileURL:(NSURL *)localFileUrl error:(NSError **)error;

- (id)initWithGitIndex:(git_index *)theIndex;
+ (id)indexWithGitIndex:(git_index *)theIndex;

// Refresh the index from the datastore
//
// error(out) - will be filled if an error occurs
//
// returns YES if refresh was successful
- (BOOL)refreshWithError:(NSError **)error;

// Clear the contents (all entry objects) of the index. This happens in memory.
// Changes can be written to the datastore by calling writeAndReturnError:
- (void)clear;

// Get entries from the index
- (GTIndexEntry *)entryAtIndex:(NSUInteger)theIndex;
- (GTIndexEntry *)entryWithName:(NSString *)name;

// Add entries to the index
- (BOOL)addEntry:(GTIndexEntry *)entry error:(NSError **)error;
- (BOOL)addFile:(NSString *)file error:(NSError **)error;

// Write the index to the datastore
//
// error(out) - will be filled if an error occurs
//
// returns YES if the write was successful.
- (BOOL)writeWithError:(NSError **)error;

@end
