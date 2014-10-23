//
//  GTRepository+Private.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 15/07/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface GTRepository ()
- (id)lookUpObjectByGitOid:(const git_oid *)oid objectType:(GTObjectType)type error:(NSError **)error;
- (id)lookUpObjectByGitOid:(const git_oid *)oid error:(NSError **)error;
@end
