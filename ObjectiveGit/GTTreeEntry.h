//
//  GTTreeEntry.h
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

@class GTTree;

NS_ASSUME_NONNULL_BEGIN

@interface GTTreeEntry : NSObject

/// Initializes the receiver.
- (nullable instancetype)initWithEntry:(const git_tree_entry *)theEntry parentTree:(nullable GTTree *)parent error:(NSError **)error;

/// Convience class initializer.
+ (nullable instancetype)entryWithEntry:(const git_tree_entry *)theEntry parentTree:(nullable GTTree *)parent error:(NSError **)error;

/// The underlying `git_tree_entry`.
- (git_tree_entry *)git_tree_entry __attribute__((objc_returns_inner_pointer));

/// The entry's parent tree. This may be nil if nil parentTree is passed in to -initWithEntry:
@property (nonatomic, strong, readonly, nullable) GTTree *tree;

/// The filename of the entry
@property (nonatomic, copy, readonly) NSString *name;

/// The UNIX file attributes of the entry.
@property (nonatomic, readonly) NSInteger attributes;

/// The SHA hash of the entry
@property (nonatomic, copy, readonly, nullable) NSString *SHA;

/// The type of GTObject that -object: will return.
@property (nonatomic, readonly) GTObjectType type;

/// The OID of the entry.
@property (nonatomic, strong, readonly, nullable) GTOID *OID;

/// Convert the entry into an GTObject
///
/// error - will be filled if an error occurs
///
/// Returns this entry as a GTObject or nil if an error occurred.
- (nullable GTObject *)GTObject:(NSError **)error;

@end


@interface GTObject (GTTreeEntry)

+ (nullable instancetype)objectWithTreeEntry:(GTTreeEntry *)treeEntry error:(NSError **)error;
- (nullable instancetype)initWithTreeEntry:(GTTreeEntry *)treeEntry error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
