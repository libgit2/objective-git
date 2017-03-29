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

#import <Foundation/Foundation.h>
#include "git2/index.h"
#import "GTObject.h"

@class GTIndex;

typedef NS_ENUM(NSInteger, GTIndexEntryStatus) {
	GTIndexEntryStatusUpdated = 0,
	GTIndexEntryStatusConflicted,
	GTIndexEntryStatusAdded,
	GTIndexEntryStatusRemoved,
	GTIndexEntryStatusUpToDate,
};

NS_ASSUME_NONNULL_BEGIN

@interface GTIndexEntry : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver with the given libgit2 index entry.
///
/// entry - The libgit2 index entry. Cannot be NULL.
/// index - The index this entry belongs to.
/// error - will be filled if an error occurs
///
/// Returns the initialized object.
- (instancetype)initWithGitIndexEntry:(const git_index_entry *)entry index:(GTIndex * _Nullable)index error:(NSError **)error NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithGitIndexEntry:(const git_index_entry *)entry;

/// The underlying `git_index_entry` object.
- (const git_index_entry *)git_index_entry __attribute__((objc_returns_inner_pointer));

/// The entry's index. This may be nil if nil is passed in to -initWithGitIndexEntry:
@property (nonatomic, strong, readonly) GTIndex * _Nullable index;

/// The repository-relative path for the entry.
@property (nonatomic, readonly, copy) NSString *path;

/// Has the entry been staged?
@property (nonatomic, getter = isStaged, readonly) BOOL staged;

/// What is the entry's status?
@property (nonatomic, readonly) GTIndexEntryStatus status;

/// The OID of the entry.
@property (nonatomic, strong, readonly) GTOID *OID;

/// Convert the entry into an GTObject
///
/// error - will be filled if an error occurs
///
/// Returns this entry as a GTObject or nil if an error occurred.
- (nullable GTObject *)GTObject:(NSError **)error;

@end

@interface GTObject (GTIndexEntry)

+ (instancetype _Nullable)objectWithIndexEntry:(GTIndexEntry *)indexEntry error:(NSError **)error;
- (instancetype _Nullable)initWithIndexEntry:(GTIndexEntry *)indexEntry error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
