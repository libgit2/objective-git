//
//  GTOID_Private.h
//  ObjectiveGitFramework
//
//  Created by PiersonBro on 2/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface GTOID ()

// Returns the underlying git_oid as a struct.
- (git_oid)git_oid_struct;

@end
