//
//  GTRepository+RemoteOperations.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 18/11/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

// A `GTCredentialProvider`, that will be used to authenticate against the remote.
extern NSString *const GTRepositoryRemoteOptionsCredentialProvider;

@interface GTRepository (RemoteOperations)

// Fetch a remote.
//
// remote  - The remote to fetch from.
// options - Options applied to the fetch operation.
//           Recognized options are :
//           `GTRemoteOptionsCredentialProvider`, which should be a GTCredentialProvider,
//			 in case authentication is needed.
// error   - The error if one occurred. Can be NULL.
//
// Returns YES if the fetch was successful, NO otherwise (and `error`, if provided,
// will point to an error describing what happened).
- (BOOL)fetchRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(void (^)(const git_transfer_progress *stats, BOOL *stop))progressBlock;

@end
