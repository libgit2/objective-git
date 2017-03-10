//
//  GTRepository+Private.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 15/07/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

NS_ASSUME_NONNULL_BEGIN

@interface GTRepository ()

- (id _Nullable)lookUpObjectByGitOid:(const git_oid *)oid objectType:(GTObjectType)type error:(NSError **)error;
- (id _Nullable)lookUpObjectByGitOid:(const git_oid *)oid error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
