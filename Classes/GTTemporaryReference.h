//
//  GTTemporaryReference.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 16/07/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface GTTemporaryReference : GTReference

+ (id)temporaryReferenceToOID:(GTOID *)oid inRepository:(GTRepository *)repository;
- (id)initWithOID:(GTOID *)oid inRepository:(GTRepository *)repository;

@end
