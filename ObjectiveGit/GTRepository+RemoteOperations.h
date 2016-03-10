//
//  GTRepository+RemoteOperations.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 18/11/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"
#import "git2/remote.h"

@class GTFetchHeadEntry;

NS_ASSUME_NONNULL_BEGIN

/// A `GTCredentialProvider`, that will be used to authenticate against the remote.
extern NSString *const GTRepositoryRemoteOptionsCredentialProvider;

/// A `GTFetchPruneOption`, that will be used to determine if the fetch should prune or not.
extern NSString *const GTRepositoryRemoteOptionsFetchPrune;

/// A `GTRemoteAutoTagOption`, that will be used to determine how the fetch should handle tags.
extern NSString *const GTRepositoryRemoteOptionsDownloadTags;

/// An enum describing the data needed for pruning.
/// See `git_fetch_prune_t`.
typedef NS_ENUM(NSInteger, GTFetchPruneOption) {
	GTFetchPruneOptionUnspecified = GIT_FETCH_PRUNE_UNSPECIFIED,
	GTFetchPruneOptionYes = GIT_FETCH_PRUNE,
	GTFetchPruneOptionNo = GIT_FETCH_NO_PRUNE,
};

@interface GTRepository (RemoteOperations)

#pragma mark - Fetch

/// Fetch a remote.
///
/// remote  - The remote to fetch from. Must not be nil.
/// options - Options applied to the fetch operation. May be nil.
///           Recognized options are :
///           `GTRepositoryRemoteOptionsCredentialProvider`
///           `GTRepositoryRemoteOptionsFetchPrune`
///           `GTRepositoryRemoteOptionsDownloadTags`
/// error   - The error if one occurred. Can be NULL.
/// progressBlock - Optional callback to receive fetch progress stats during the
///                 transfer. May be nil.
///
/// Returns YES if the fetch was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)fetchRemote:(GTRemote *)remote withOptions:(nullable NSDictionary *)options error:(NSError **)error progress:(nullable void (^)(const git_transfer_progress *stats, BOOL *stop))progressBlock;

/// Enumerate all available fetch head entries.
///
/// error - The error if one ocurred. Can be NULL.
/// block - A block to execute for each FETCH_HEAD entry. `fetchHeadEntry` will
///         be the current fetch head entry. Setting `stop` to YES will cause
///         enumeration to stop after the block returns. Must not be nil.
///
/// Returns YES if the operation succedded, NO otherwise.
- (BOOL)enumerateFetchHeadEntriesWithError:(NSError **)error usingBlock:(void (^)(GTFetchHeadEntry *fetchHeadEntry, BOOL *stop))block;

/// Convenience method for -enumerateFetchHeadEntriesWithError:usingBlock: that retuns an NSArray with all the fetch head entries.
///
/// error - The error if one ocurred. Can be NULL.
///
/// Retruns a (possibly empty) array with GTFetchHeadEntry objects. Will not be nil.
- (NSArray<GTFetchHeadEntry *> *)fetchHeadEntriesWithError:(NSError **)error;

#pragma mark - Push

/// Push a single branch to a remote.
///
/// branch        - The branch to push. Must not be nil.
/// remote        - The remote to push to. Must not be nil.
/// options       - Options applied to the push operation. Can be NULL.
///                 Recognized options are:
///                 `GTRepositoryRemoteOptionsCredentialProvider`
/// error         - The error if one occurred. Can be NULL.
/// progressBlock - An optional callback for monitoring progress. May be NULL.
///
/// Returns YES if the push was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)pushBranch:(GTBranch *)branch toRemote:(GTRemote *)remote withOptions:(nullable NSDictionary *)options error:(NSError **)error progress:(nullable void (^)(unsigned int current, unsigned int total, size_t bytes, BOOL *stop))progressBlock;

/// Push an array of branches to a remote.
///
/// branches      - An array of branches to push. Must not be nil.
/// remote        - The remote to push to. Must not be nil.
/// options       - Options applied to the push operation. Can be NULL.
///                 Recognized options are:
///                 `GTRepositoryRemoteOptionsCredentialProvider`
/// error         - The error if one occurred. Can be NULL.
/// progressBlock - An optional callback for monitoring progress. May be NULL.
///
/// Returns YES if the push was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)pushBranches:(NSArray<GTBranch *> *)branches toRemote:(GTRemote *)remote withOptions:(nullable NSDictionary *)options error:(NSError **)error progress:(nullable void (^)(unsigned int current, unsigned int total, size_t bytes, BOOL *stop))progressBlock;

/// Delete a remote branch
///
/// branch        - The branch to push. Must not be nil.
/// remote        - The remote to push to. Must not be nil.
/// options       - Options applied to the push operation. Can be NULL.
///                 Recognized options are:
///                 `GTRepositoryRemoteOptionsCredentialProvider`
/// error         - The error if one occurred. Can be NULL.
///
/// Returns YES if the push was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)deleteBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(nullable NSDictionary *)options error:(NSError **)error;
@end

NS_ASSUME_NONNULL_END
