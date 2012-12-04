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

NSString *const GTDiffOptionsFlagsKey = @"GTDiffOptionsFlagsKey";
NSString *const GTDiffOptionsContextLinesKey = @"GTDiffOptionsContextLinesKey";
NSString *const GTDiffOptionsInterHunkLinesKey = @"GTDiffOptionsInterHunkLinesKey";
NSString *const GTDiffOptionsOldPrefixKey = @"GTDiffOptionsOldPrefixKey";
NSString *const GTDiffOptionsNewPrefixKey = @"GTDiffOptionsNewPrefixKey";
NSString *const GTDiffOptionsMaxSizeKey = @"GTDiffOptionsMaxSizeKey";

@implementation GTDiff

+ (git_diff_options *)optionsStructFromDictionary:(NSDictionary *)dictionary {
	if (dictionary == nil) return NULL;
	
	git_diff_options *newOptions = malloc(sizeof(git_diff_options));
	
	NSNumber *flagsNumber = dictionary[GTDiffOptionsFlagsKey];
	if (flagsNumber != nil) newOptions->flags = (uint32_t)flagsNumber.unsignedIntegerValue;
	
	NSNumber *contextLinesNumber = dictionary[GTDiffOptionsContextLinesKey];
	if (contextLinesNumber != nil) newOptions->context_lines = (uint16_t)contextLinesNumber.unsignedIntegerValue;
	
	NSNumber *interHunkLinesNumber = dictionary[GTDiffOptionsInterHunkLinesKey];
	if (interHunkLinesNumber != nil) newOptions->interhunk_lines = (uint16_t)interHunkLinesNumber.unsignedIntegerValue;
	
	NSString *oldPrefix = dictionary[GTDiffOptionsOldPrefixKey];
	if (oldPrefix != nil) newOptions->old_prefix = (char *)oldPrefix.UTF8String;
	
	NSString *newPrefix = dictionary[GTDiffOptionsNewPrefixKey];
	if (newPrefix != nil) newOptions->new_prefix = (char *)newPrefix.UTF8String;
	
	NSNumber *maxSizeNumber = dictionary[GTDiffOptionsMaxSizeKey];
	if (maxSizeNumber != nil) newOptions->max_size = (uint16_t)maxSizeNumber.unsignedIntegerValue;
	
	return newOptions;
}

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree inRepository:(GTRepository *)repository withOptions:(NSDictionary *)options {
	git_diff_options *optionsStruct = [self optionsStructFromDictionary:options];
	git_diff_list *diffList;
	int returnValue = git_diff_tree_to_tree(&diffList, repository.git_repository, oldTree.git_tree, newTree.git_tree, optionsStruct);
	free(optionsStruct);
	if (returnValue != GIT_OK) return nil;
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffIndexToTree:(GTTree *)tree inRepository:(GTRepository *)repository withOptions:(NSDictionary *)options {
	git_diff_options *optionsStruct = [self optionsStructFromDictionary:options];
	git_diff_list *diffList;
	int returnValue = git_diff_index_to_tree(&diffList, repository.git_repository, tree.git_tree, NULL, optionsStruct);
	free(optionsStruct);
	if (returnValue != GIT_OK) return nil;
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffWorkingDirectoryToIndexInRepository:(GTRepository *)repository withOptions:(NSDictionary *)options {
	git_diff_options *optionsStruct = [self optionsStructFromDictionary:options];
	git_diff_list *diffList;
	int returnValue = git_diff_workdir_to_index(&diffList, repository.git_repository, NULL, optionsStruct);
	free(optionsStruct);
	if (returnValue != GIT_OK) return nil;
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffWorkingDirectoryToTree:(GTTree *)tree inRepository:(GTRepository *)repository withOptions:(NSDictionary *)options {
	git_diff_options *optionsStruct = [self optionsStructFromDictionary:options];
	git_diff_list *diffList;
	int returnValue = git_diff_workdir_to_tree(&diffList, repository.git_repository, tree.git_tree, optionsStruct);
	free(optionsStruct);
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

- (void)enumerateDeltasUsingBlock:(BOOL(^)(GTDiffDelta *delta))block {
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
