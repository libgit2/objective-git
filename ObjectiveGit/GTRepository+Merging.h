//
//  GTRepository+Merging.h
//  ObjectiveGitFramework
//
//  Created by Piet Brauer on 02/03/16.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"
#import "git2/merge.h"

NS_ASSUME_NONNULL_BEGIN

/// UserInfo key for conflicted files when pulling fails with a merge conflict
extern NSString * const GTPullMergeConflictedFiles;

/// An enum describing the result of the merge analysis.
/// See `git_merge_analysis_t`.
typedef NS_OPTIONS(NSInteger, GTMergeAnalysis) {
	GTMergeAnalysisNone = GIT_MERGE_ANALYSIS_NONE,
	GTMergeAnalysisNormal = GIT_MERGE_ANALYSIS_NORMAL,
	GTMergeAnalysisUpToDate = GIT_MERGE_ANALYSIS_UP_TO_DATE,
	GTMergeAnalysisUnborn = GIT_MERGE_ANALYSIS_UNBORN,
	GTMergeAnalysisFastForward = GIT_MERGE_ANALYSIS_FASTFORWARD,
};

@interface GTRepository (Merging)

/// Enumerate all available merge head entries.
///
/// error - The error if one ocurred. Can be NULL.
/// block - A block to execute for each MERGE_HEAD entry. `mergeHeadEntry` will
///         be the current merge head entry. Setting `stop` to YES will cause
///         enumeration to stop after the block returns. Must not be nil.
///
/// Returns YES if the operation succedded, NO otherwise.
- (BOOL)enumerateMergeHeadEntriesWithError:(NSError **)error usingBlock:(void (^)(GTOID *mergeHeadEntry, BOOL *stop))block;

/// Convenience method for -enumerateMergeHeadEntriesWithError:usingBlock: that retuns an NSArray with all the fetch head entries.
///
/// error - The error if one ocurred. Can be NULL.
///
/// Retruns a (possibly empty) array with GTOID objects. Will not be nil.
- (NSArray <GTOID *>*)mergeHeadEntriesWithError:(NSError **)error;

/// Merge Branch into current branch
///
/// fromBranch - The branch to merge from.
/// error      - The error if one occurred. Can be NULL.
///
/// Returns YES if the merge was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)mergeBranchIntoCurrentBranch:(GTBranch *)fromBranch withError:(NSError **)error;

/// Analyze which merge to perform.
///
/// analysis   - The resulting analysis.
/// fromBranch - The branch to merge from.
/// error      - The error if one occurred. Can be NULL.
///
/// Returns YES if the analysis was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)analyzeMerge:(GTMergeAnalysis *)analysis fromBranch:(GTBranch *)fromBranch error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
