//
//  GTDiff.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 29/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

#import "GTDiffDelta.h"

@class GTTree;

@interface GTDiff : NSObject

@property (nonatomic, readonly, assign) git_diff_list *git_diff_list;
@property (nonatomic, readonly, strong) NSArray *deltas;

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree options:(NSUInteger)options;
+ (GTDiff *)diffIndexToOldTree:(GTTree *)oldTree withOptions:(NSUInteger)options;
+ (GTDiff *)diffWorkingDirectoryToIndexWithOptions:(NSUInteger)options;
+ (GTDiff *)diffWorkingDirectoryToTree:(GTTree *)tree withOptions:(NSUInteger)options;

- (instancetype)initWithGitDiffList:(git_diff_list *)diffList;
- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType;

@end
