//
//  GTRepository+Pushing.h
//  ObjectiveGitFramework
//
//  Created by John Beatty on 1/12/14.
//  Copyright (c) 2014 Objective Products LLC. All rights reserved.
//

#import "GTRepository.h"

@class GTRemote;
@class GTBranch;

// A `GTCredentialProvider`, that will be used to authenticate against the remote.
extern NSString *const GTRepositoryPushingOptionsCredentialProvider;

@interface GTRepository (Pushing)

- (void)pushBranch:(GTBranch *)branch toRemote:(GTRemote *)_remote options:(NSDictionary *)pushOptions;

@end
