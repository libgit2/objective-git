//
//  GTObject+Private.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 15/07/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface GTObject ()
+ (instancetype)lookupWithGitOID:(const git_oid *)git_oid inRepository:(GTRepository *)repository error:(NSError **)error;
@end
