//
//  GTRepository+Pull.h
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/17/15.
//  Copyright © 2015 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"
#import "git2/merge.h"

NS_ASSUME_NONNULL_BEGIN

/// An enum describing the result of the merge analysis.
/// See `git_merge_analysis_t`.
typedef NS_OPTIONS(NSInteger, GTMergeAnalysis) {
	GTMergeAnalysisNone = GIT_MERGE_ANALYSIS_NONE,
	GTMergeAnalysisNormal = GIT_MERGE_ANALYSIS_NORMAL,
	GTMergeAnalysisUpToDate = GIT_MERGE_ANALYSIS_UP_TO_DATE,
	GTMergeAnalysisUnborn = GIT_MERGE_ANALYSIS_UNBORN,
	GTMergeAnalysisFastForward = GIT_MERGE_ANALYSIS_FASTFORWARD,
};

typedef void (^GTRemoteFetchTransferProgressBlock)(const git_transfer_progress *progress, BOOL *stop);

@interface GTRepository (Pull)

#pragma mark - Pull

/// Pull a single branch from a remote.
///
/// branch        - The branch to pull.
/// remote        - The remote to pull from.
/// options       - Options applied to the fetch operation.
///                 Recognized options are:
///                 `GTRepositoryRemoteOptionsCredentialProvider`
/// error         - The error if one occurred. Can be NULL.
/// progressBlock - An optional callback for monitoring progress.
///
/// Returns YES if the pull was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(nullable NSDictionary *)options error:(NSError **)error progress:(nullable GTRemoteFetchTransferProgressBlock)progressBlock;

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
