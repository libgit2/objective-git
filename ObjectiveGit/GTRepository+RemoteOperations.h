//
//  GTRepository+RemoteOperations.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 18/11/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

@class GTFetchHeadEntry;

/// A `GTCredentialProvider`, that will be used to authenticate against the remote.
extern NSString *const GTRepositoryRemoteOptionsCredentialProvider;

@interface GTRepository (RemoteOperations)

#pragma mark - Fetch

/// Fetch a remote.
///
/// remote  - The remote to fetch from.
/// options - Options applied to the fetch operation.
///           Recognized options are :
///           `GTRepositoryRemoteOptionsCredentialProvider`
/// error   - The error if one occurred. Can be NULL.
///
/// Returns YES if the fetch was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)fetchRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(void (^)(const git_transfer_progress *stats, BOOL *stop))progressBlock;

/// Enumerate all available fetch head entries.
///
/// error - The error if one ocurred. Can be NULL.
/// block - A block to execute for each FETCH_HEAD entry. `fetchHeadEntry` will be the current
///         fetch head entry. Setting `stop` to YES will cause enumeration to stop after the block returns.
///
/// Returns YES if the operation succedded, NO otherwise.
- (BOOL)enumerateFetchHeadEntriesWithError:(NSError **)error usingBlock:(void (^)(GTFetchHeadEntry *fetchHeadEntry, BOOL *stop))block;

/// Convenience method for -enumerateFetchHeadEntriesWithError:usingBlock: that retuns an NSArray with all the fetch head entries.
///
/// error - The error if one ocurred. Can be NULL.
///
/// Retruns an array with GTFetchHeadEntry objects
- (NSArray *)fetchHeadEntriesWithError:(NSError **)error;

#pragma mark - Push

/// Push a single branch to a remote.
///
/// branch        - The branch to push.
/// remote        - The remote to push to.
/// options       - Options applied to the push operation.
///                 Recognized options are:
///                 `GTRepositoryRemoteOptionsCredentialProvider`
/// error         - The error if one occurred. Can be NULL.
/// progressBlock - An optional callback for monitoring progress.
///
/// Returns YES if the push was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)pushBranch:(GTBranch *)branch toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(void (^)(unsigned int current, unsigned int total, size_t bytes, BOOL *stop))progressBlock;

/// Push an array of branches to a remote.
///
/// branches      - An array of branches to push.
/// remote        - The remote to push to.
/// options       - Options applied to the push operation.
///                 Recognized options are:
///                 `GTRepositoryRemoteOptionsCredentialProvider`
/// error         - The error if one occurred. Can be NULL.
/// progressBlock - An optional callback for monitoring progress.
///
/// Returns YES if the push was successful, NO otherwise (and `error`, if provided,
/// will point to an error describing what happened).
- (BOOL)pushBranches:(NSArray *)branches toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(void (^)(unsigned int current, unsigned int total, size_t bytes, BOOL *stop))progressBlock;

@end
