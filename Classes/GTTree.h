//
//  GTTree.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>
#import "GTObject.h"

@class GTTreeEntry;

@interface GTTree : GTObject {}

@property (nonatomic, assign) git_tree *tree;
@property (nonatomic, readonly) NSInteger entryCount;

- (void)clear;
- (GTTreeEntry *)entryAtIndex:(NSInteger)index;
- (GTTreeEntry *)entryByName:(NSString *)name;
- (GTTreeEntry *)addEntryWithObjId:(NSString *)oid filename:(NSString *)filename mode:(NSInteger *)mode error:(NSError **)error;

@end
