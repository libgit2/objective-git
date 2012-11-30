//
//  GTDiff.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 29/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiff.h"

#import "GTDiffDelta.h"
#import "GTRepository.h"
#import "GTTree.h"

@implementation GTDiff

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree forRepository:(GTRepository *)repository withOptions:(NSDictionary *)options {
	git_diff_list *diffList;
	int returnValue = git_diff_tree_to_tree(&diffList, repository.git_repository, oldTree.git_tree, newTree.git_tree, NULL);
	if (returnValue != GIT_OK) return nil;
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffIndexToOldTree:(GTTree *)oldTree forRepository:(GTRepository *)repository withOptions:(NSDictionary *)options {
	git_diff_list *diffList;
	int returnValue = git_diff_index_to_tree(&diffList, repository.git_repository, oldTree.git_tree, NULL, NULL);
	if (returnValue != GIT_OK) return nil;
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffWorkingDirectoryToIndexForRepository:(GTRepository *)repository withOptions:(NSDictionary *)options {
	git_diff_list *diffList;
	int returnValue = git_diff_workdir_to_index(&diffList, repository.git_repository, NULL, NULL);
	if (returnValue != GIT_OK) return nil;
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffWorkingDirectoryToTree:(GTTree *)tree forRepository:(GTRepository *)repository withOptions:(NSDictionary *)options {
	git_diff_list *diffList;
	int returnValue = git_diff_workdir_to_tree(&diffList, repository.git_repository, tree.git_tree, NULL);
	if (returnValue != GIT_OK) return nil;
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

- (instancetype)initWithGitDiffList:(git_diff_list *)diffList {
	self = [super init];
	if (self == nil) return nil;
	
	_git_diff_list = diffList;
	
	return self;
}

- (void)dealloc
{
	git_diff_list_free(self.git_diff_list);
}

#pragma mark - Properties

- (void)enumerateDeltasWithBlock:(GTDiffDeltaProcessingBlock)block {
	for (NSUInteger idx = 0; idx < self.deltaCount; idx ++) {
		git_diff_patch *patch;
		int result = git_diff_get_patch(&patch, NULL, self.git_diff_list, idx);
		if (result != GIT_OK) continue;
		GTDiffDelta *delta = [[GTDiffDelta alloc] initWithGitPatch:patch];
		if (!block(delta)) return;
	}
}

- (NSUInteger)deltaCount {
	return git_diff_num_deltas(self.git_diff_list);
}

- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType {
	return git_diff_num_deltas_of_type(self.git_diff_list, (git_delta_t)deltaType);
}

@end
