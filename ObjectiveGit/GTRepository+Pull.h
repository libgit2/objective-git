//
//  GTRepository+Pull.h
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/17/15.
//  Copyright © 2015 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

NS_ASSUME_NONNULL_BEGIN

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
///                 `GTRepositoryRemoteOptionsFetchPrune`
///                 `GTRepositoryRemoteOptionsDownloadTags`
/// error         - The error if one occurred. Can be NULL.
/// progressBlock - An optional callback for monitoring progress.
///
/// Returns YES if the pull was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(nullable NSDictionary *)options error:(NSError **)error progress:(nullable GTRemoteFetchTransferProgressBlock)progressBlock;

@end

NS_ASSUME_NONNULL_END
