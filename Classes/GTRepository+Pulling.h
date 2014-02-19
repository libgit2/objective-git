//
//  GTRepository+Pulling.h
//  ObjectiveGitFramework
//
//  Created by John Beatty on 1/13/14.
//  Copyright (c) 2014 Objective Products LLC. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface GTRepository (Pulling)

- (void)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)_remote options:(NSDictionary *)pullOptions;

@end
