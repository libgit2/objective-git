//
//  GTRepository+Merging.h
//  ObjectiveGitFramework
//
//  Created by Piet Brauer on 02/03/16.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

NS_ASSUME_NONNULL_BEGIN

@interface GTRepository (Merging)

/// Enumerate all available merge head entries.
///
/// error - The error if one ocurred. Can be NULL.
/// block - A block to execute for each MERGE_HEAD entry. `mergeHeadEntry` will
///         be the current merge head entry. Setting `stop` to YES will cause
///         enumeration to stop after the block returns. Must not be nil.
///
/// Returns YES if the operation succedded, NO otherwise.
- (BOOL)enumerateMergeHeadEntriesWithError:(NSError **)error usingBlock:(void (^)(GTCommit *mergeHeadEntry, BOOL *stop))block;

/// Convenience method for -enumerateMergeHeadEntriesWithError:usingBlock: that retuns an NSArray with all the fetch head entries.
///
/// error - The error if one ocurred. Can be NULL.
///
/// Retruns a (possibly empty) array with GTCommit objects. Will not be nil.
- (NSArray <GTCommit *>*)mergeHeadEntriesWithError:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
