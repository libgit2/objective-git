//
//  GTDiff.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 29/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

#import "GTDiffDelta.h"

@class GTRepository;
@class GTTree;

@interface GTDiff : NSObject

@property (nonatomic, readonly, assign) git_diff_list *git_diff_list;
@property (nonatomic, readonly, strong) NSArray *deltas;

//TODO: Need to settle on a method for sending in the options struct

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree forRepository:(GTRepository *)repository withOptions:(NSUInteger)options;
+ (GTDiff *)diffIndexToOldTree:(GTTree *)oldTree forRepository:(GTRepository *)repository withOptions:(NSUInteger)options;
+ (GTDiff *)diffWorkingDirectoryToIndexForRepository:(GTRepository *)repository withOptions:(NSUInteger)options;
+ (GTDiff *)diffWorkingDirectoryToTree:(GTTree *)tree forRepository:(GTRepository *)repository withOptions:(NSUInteger)options;

- (instancetype)initWithGitDiffList:(git_diff_list *)diffList;
- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType;

@end
