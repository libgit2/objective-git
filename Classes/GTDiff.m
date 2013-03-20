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
#import "GTCommit.h"

#import "NSError+Git.h"

NSString *const GTDiffOptionsFlagsKey = @"GTDiffOptionsFlagsKey";
NSString *const GTDiffOptionsContextLinesKey = @"GTDiffOptionsContextLinesKey";
NSString *const GTDiffOptionsInterHunkLinesKey = @"GTDiffOptionsInterHunkLinesKey";
NSString *const GTDiffOptionsOldPrefixKey = @"GTDiffOptionsOldPrefixKey";
NSString *const GTDiffOptionsNewPrefixKey = @"GTDiffOptionsNewPrefixKey";
NSString *const GTDiffOptionsMaxSizeKey = @"GTDiffOptionsMaxSizeKey";
NSString *const GTDiffOptionsPathSpecArrayKey = @"GTDiffOptionsPathSpecArrayKey";

NSString *const GTDiffFindOptionsFlagsKey = @"GTDiffFindOptionsFlagsKey";
NSString *const GTDiffFindOptionsRenameThresholdKey = @"GTDiffFindOptionsRenameThresholdKey";
NSString *const GTDiffFindOptionsRenameFromRewriteThresholdKey = @"GTDiffFindOptionsRenameFromRewriteThresholdKey";
NSString *const GTDiffFindOptionsCopyThresholdKey = @"GTDiffFindOptionsCopyThresholdKey";
NSString *const GTDiffFindOptionsBreakRewriteThresholdKey = @"GTDiffFindOptionsBreakRewriteThresholdKey";
NSString *const GTDiffFindOptionsTargetLimitKey = @"GTDiffFindOptionsTargetLimitKey";

@implementation GTDiff

+ (git_diff_options *)optionsStructFromDictionary:(NSDictionary *)dictionary {
	if (dictionary == nil || dictionary.count < 1) return nil;
	
	git_diff_options newOptions = GIT_DIFF_OPTIONS_INIT;
	
	NSNumber *flagsNumber = dictionary[GTDiffOptionsFlagsKey];
	if (flagsNumber != nil) newOptions.flags = (uint32_t)flagsNumber.unsignedIntegerValue;
	
	NSNumber *contextLinesNumber = dictionary[GTDiffOptionsContextLinesKey];
	if (contextLinesNumber != nil) newOptions.context_lines = (uint16_t)contextLinesNumber.unsignedIntegerValue;
	
	NSNumber *interHunkLinesNumber = dictionary[GTDiffOptionsInterHunkLinesKey];
	if (interHunkLinesNumber != nil) newOptions.interhunk_lines = (uint16_t)interHunkLinesNumber.unsignedIntegerValue;
	
	// We cast to char* below to work around a current bug in libgit2, which is
	// fixed in https://github.com/libgit2/libgit2/pull/1118
	
	NSString *oldPrefix = dictionary[GTDiffOptionsOldPrefixKey];
	if (oldPrefix != nil) newOptions.old_prefix = (char *)oldPrefix.UTF8String;
	
	NSString *newPrefix = dictionary[GTDiffOptionsNewPrefixKey];
	if (newPrefix != nil) newOptions.new_prefix = (char *)newPrefix.UTF8String;
	
	NSNumber *maxSizeNumber = dictionary[GTDiffOptionsMaxSizeKey];
	if (maxSizeNumber != nil) newOptions.max_size = (uint16_t)maxSizeNumber.unsignedIntegerValue;
	
	NSArray *pathSpec = dictionary[GTDiffOptionsPathSpecArrayKey];
	if (pathSpec != nil) {
		char **cStrings = malloc(sizeof(*cStrings) * pathSpec.count);
		for (NSUInteger idx = 0; idx < pathSpec.count; idx ++) {
			cStrings[idx] = (char *)[pathSpec[idx] cStringUsingEncoding:NSUTF8StringEncoding];
		}
		
		git_strarray optionsPathSpec = {.strings = cStrings, .count = pathSpec.count};
		newOptions.pathspec = optionsPathSpec;
	}
	
	git_diff_options *returnOptions = malloc(sizeof(*returnOptions));
	memcpy(returnOptions, &newOptions, sizeof(*returnOptions));
	
	return returnOptions;
}

+ (void)freeOptionsStruct:(git_diff_options *)options {
	if (options == NULL) return;
	free(options->pathspec.strings);
	free(options);
}

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert([oldTree.repository isEqual:newTree.repository]);
	
	git_diff_options *optionsStruct = [self optionsStructFromDictionary:options];
	git_diff_list *diffList;
	int returnValue = git_diff_tree_to_tree(&diffList, oldTree.repository.git_repository, oldTree.git_tree, newTree.git_tree, optionsStruct);
	[self freeOptionsStruct:optionsStruct];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue withAdditionalDescription:@"Failed to create diff."];
		return nil;
	}
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffIndexFromTree:(GTTree *)tree options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(tree != nil);
	
	git_diff_options *optionsStruct = [self optionsStructFromDictionary:options];
	git_diff_list *diffList;
	int returnValue = git_diff_tree_to_index(&diffList, tree.repository.git_repository, tree.git_tree, NULL, optionsStruct);
	[self freeOptionsStruct:optionsStruct];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue withAdditionalDescription:@"Failed to create diff."];
		return nil;
	}
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffIndexToWorkingDirectoryInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	
	git_diff_options *optionsStruct = [self optionsStructFromDictionary:options];
	git_diff_list *diffList;
	int returnValue = git_diff_index_to_workdir(&diffList, repository.git_repository, NULL, optionsStruct);
	[self freeOptionsStruct:optionsStruct];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue withAdditionalDescription:@"Failed to create diff."];
		return nil;
	}
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffWorkingDirectoryFromTree:(GTTree *)tree options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(tree != nil);
	
	git_diff_options *optionsStruct = [self optionsStructFromDictionary:options];
	git_diff_list *diffList;
	int returnValue = git_diff_tree_to_workdir(&diffList, tree.repository.git_repository, tree.git_tree, optionsStruct);
	[self freeOptionsStruct:optionsStruct];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue withAdditionalDescription:@"Failed to create diff."];
		return nil;
	}
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffWorkingDirectoryToHEADInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);

	GTCommit *HEADCommit = (GTCommit *)[repository lookupObjectByRefspec:@"HEAD" error:error];
	if (HEADCommit == nil) return nil;

	GTDiff *HEADIndexDiff = [GTDiff diffIndexFromTree:HEADCommit.tree options:options error:error];
	if (HEADIndexDiff == nil) return nil;

	GTDiff *WDDiff = [GTDiff diffIndexToWorkingDirectoryInRepository:repository options:options error:error];
	if (WDDiff == nil) return nil;

	git_diff_merge(HEADIndexDiff.git_diff_list, WDDiff.git_diff_list);

	return HEADIndexDiff;
}

- (instancetype)initWithGitDiffList:(git_diff_list *)diffList {
	NSParameterAssert(diffList != NULL);
	
	self = [super init];
	if (self == nil) return nil;
	
	_git_diff_list = diffList;
	
	return self;
}

- (void)dealloc {
	git_diff_list_free(self.git_diff_list);
}

- (void)enumerateDeltasUsingBlock:(void (^)(GTDiffDelta *delta, BOOL *stop))block {
	NSParameterAssert(block != nil);
	
	for (NSUInteger idx = 0; idx < self.deltaCount; idx ++) {
		git_diff_patch *patch;
		int result = git_diff_get_patch(&patch, NULL, self.git_diff_list, idx);
		if (result != GIT_OK) continue;
		GTDiffDelta *delta = [[GTDiffDelta alloc] initWithGitPatch:patch];
		BOOL stop = NO;
		block(delta, &stop);
		if (stop) return;
	}
}

- (NSUInteger)deltaCount {
	return git_diff_num_deltas(self.git_diff_list);
}

- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType {
	return git_diff_num_deltas_of_type(self.git_diff_list, (git_delta_t)deltaType);
}

- (BOOL)findOptionsStructWithDictionary:(NSDictionary *)dictionary optionsStruct:(git_diff_find_options *)newOptions {
	if (dictionary == nil || dictionary.count < 1) return NO;
		
	NSNumber *flagsNumber = dictionary[GTDiffFindOptionsFlagsKey];
	if (flagsNumber != nil) newOptions->flags = (uint32_t)flagsNumber.unsignedIntegerValue;
	
	NSNumber *renameThresholdNumber = dictionary[GTDiffFindOptionsRenameThresholdKey];
	if (renameThresholdNumber != nil) newOptions->rename_threshold = renameThresholdNumber.unsignedIntValue;
	
	NSNumber *renameFromRewriteThresholdNumber = dictionary[GTDiffFindOptionsRenameFromRewriteThresholdKey];
	if (renameFromRewriteThresholdNumber != nil) newOptions->rename_from_rewrite_threshold = renameFromRewriteThresholdNumber.unsignedIntValue;
	
	NSNumber *copyThresholdNumber = dictionary[GTDiffFindOptionsCopyThresholdKey];
	if (copyThresholdNumber != nil) newOptions->copy_threshold = copyThresholdNumber.unsignedIntValue;
	
	NSNumber *breakRewriteThresholdNumber = dictionary[GTDiffFindOptionsBreakRewriteThresholdKey];
	if (renameThresholdNumber != nil) newOptions->break_rewrite_threshold = breakRewriteThresholdNumber.unsignedIntValue;
	
	NSNumber *targetLimitNumber = dictionary[GTDiffFindOptionsTargetLimitKey];
	if (targetLimitNumber != nil) newOptions->target_limit = targetLimitNumber.unsignedIntValue;
	
	return YES;
}

- (void)findSimilarWithOptions:(NSDictionary *)options {
	git_diff_find_options findOptions = GIT_DIFF_FIND_OPTIONS_INIT;
	BOOL findOptionsCreated = [self findOptionsStructWithDictionary:options optionsStruct:&findOptions];
	git_diff_find_similar(self.git_diff_list, (findOptionsCreated ? &findOptions : NULL));
}

@end
