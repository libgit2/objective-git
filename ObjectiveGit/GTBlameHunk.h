//
//  GTBlameHunk.h
//  ObjectiveGitFramework
//
//  Created by David Catmull on 11/6/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/blame.h"

@class GTOID;
@class GTSignature;

NS_ASSUME_NONNULL_BEGIN

/// A `GTBlameHunk` is an object that provides authorship info for a set of lines in a `GTBlame`.
@interface GTBlameHunk : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer.
///
/// hunk - A git_blame_hunk to wrap. May not be NULL.
///
/// Returns a blame hunk, or nil if initialization failed.
- (nullable instancetype)initWithGitBlameHunk:(git_blame_hunk)hunk NS_DESIGNATED_INITIALIZER;

/// A NSRange where `location` is the (1 based) starting line number,
/// and `length` is the number of lines in the hunk.
@property (nonatomic, readonly) NSRange lines;

/// The OID of the commit where this hunk was last changed.
@property (nonatomic, readonly, copy, nullable) GTOID *finalCommitOID;

/// The signature of the commit where this hunk was last changed.
@property (nonatomic, readonly, nullable) GTSignature *finalSignature;

/// The path of the file in the original commit.
@property (nonatomic, readonly, copy) NSString *originalPath;

/// `YES` if the blame stopped trying before the commit where the line was added was found.
/// This could happen if you use `GTBlameOptionsOldestCommitOID`.
@property (nonatomic, getter = isBoundary, readonly) BOOL boundary;

/// The git_blame_hunk represented by the receiver.
@property (nonatomic, readonly) git_blame_hunk git_blame_hunk;

@end

NS_ASSUME_NONNULL_END
