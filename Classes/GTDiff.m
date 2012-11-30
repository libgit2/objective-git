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

int GTDiffFilesCallback(void *data, const git_diff_delta *delta, float progress);

@interface GTDiff ()

@property (nonatomic, strong) NSMutableArray *deltasBuilderArray;

@end

@implementation GTDiff

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree forRepository:(GTRepository *)repository withOptions:(NSUInteger)options {
	git_diff_list *diffList;
	int returnValue = git_diff_tree_to_tree(repository.git_repository, nil, oldTree.git_tree, newTree.git_tree, &diffList);
	if (returnValue != GIT_OK) return nil;
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffIndexToOldTree:(GTTree *)oldTree forRepository:(GTRepository *)repository withOptions:(NSUInteger)options {
	git_diff_list *diffList;
	int returnValue = git_diff_index_to_tree(repository.git_repository, nil, oldTree.git_tree, &diffList);
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

- (NSArray *)deltas {
	if (self.deltasBuilderArray != nil) {
		size_t count = git_diff_num_deltas(self.git_diff_list);
		self.deltasBuilderArray = [NSMutableArray arrayWithCapacity:count];
		git_diff_foreach(self.git_diff_list, (__bridge void *)(self.deltasBuilderArray), GTDiffFilesCallback, nil, nil);
	}
	
	return [NSArray arrayWithArray:self.deltasBuilderArray];
}

- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType {
	return git_diff_num_deltas_of_type(self.git_diff_list, (git_delta_t)deltaType);
}

@end

int GTDiffFilesCallback(void *data, const git_diff_delta *delta, float progress) {
	GTDiffDelta *gtDelta = [[GTDiffDelta alloc] initWithGitDelta:(git_diff_delta *)delta];
	NSMutableArray *passedArray = (__bridge NSMutableArray *)data;
	if (passedArray != nil)[passedArray addObject:gtDelta];
	return 0;
}
