//
//  GTTreeEntry.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>

@class GTTree;
@class GTObject;

@interface GTTreeEntry : NSObject {}

@property (nonatomic, assign) git_tree_entry *entry;
@property (nonatomic, copy) NSString *name;
@property (nonatomic) NSInteger attributes;
@property (nonatomic, copy) NSString *sha;
@property (nonatomic, retain) GTTree *tree;

- (GTObject *)toObjectAndReturnError:(NSError **)error;

@end
