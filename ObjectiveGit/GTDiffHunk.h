//
//  GTDiffHunk.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTDiffLine;
@class GTDiffPatch;

NS_ASSUME_NONNULL_BEGIN

/// A class representing a hunk within a diff patch.
@interface GTDiffHunk : NSObject

/// The header of the hunk.
@property (nonatomic, readonly, copy) NSString *header;

/// The number of lines represented in the hunk.
@property (nonatomic, readonly) NSUInteger lineCount;

- (instancetype)init NS_UNAVAILABLE;

/// Designated initialiser.
///
/// The contents of a hunk are lazily loaded, therefore we initialise the object
/// simply with the patch it originates from and which hunk index it represents.
///
/// patch     - The patch the hunk originates from. Must not be nil.
/// hunkIndex - The hunk's index within the patch.
///
/// Returns the initialized instance.
- (nullable instancetype)initWithPatch:(GTDiffPatch *)patch hunkIndex:(NSUInteger)hunkIndex NS_DESIGNATED_INITIALIZER;

/// Perfoms the given block on each line in the hunk.
///
/// Note that this method blocks during the enumeration.
///
/// error - A pointer to an NSError that will be set if one occurs.
/// block - A block to execute on each line. Setting `stop` to `NO` will
///         immediately stop the enumeration and return from the method. Must not
///         be nil.
/// Return YES if the enumeration was successful, NO otherwise (and an error will
/// be set in `error`).
- (BOOL)enumerateLinesInHunk:(NSError **)error usingBlock:(void (^)(GTDiffLine *line, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
