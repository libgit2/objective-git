//
//  GTTree.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
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


#import "GTObject.h"

@class GTTreeEntry;


@interface GTTree : GTObject {}

@property (nonatomic, readonly) git_tree *git_tree;

// Get the number of entries
//
// returns the number of entries in this tree
- (NSUInteger)numberOfEntries;

// Get a entry at the specified index
//
// index - index to retreive entry from
//
// returns a GTTreeEntry or nil if there is nothing at the index
- (GTTreeEntry *)entryAtIndex:(NSUInteger)index;

// Get a entry by name
//
// name - the name of the entry
//
// returns a GTTreeEntry or nil if there is nothing with the specified name
- (GTTreeEntry *)entryWithName:(NSString *)name;

/*
// Add an entry to the index
//
// sha - the sha of the file to add
// filename - the name of the file to add
// mode - the file mode
// error(out) - will be filled if an error occurs
//
// returns the added GTTreeEntry or nil if an error occurred
- (GTTreeEntry *)addEntryWithSha:(NSString *)sha filename:(NSString *)filename mode:(NSInteger *)mode error:(NSError **)error;
*/

@end
