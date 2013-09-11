//
//  GTDiff.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 29/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiff.h"

#import "GTRepository.h"
#import "GTTree.h"
#import "GTCommit.h"

#import "NSArray+StringArray.h"
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
NSString *const GTDiffFindOptionsRenameLimitKey = @"GTDiffFindOptionsRenameLimitKey";

@interface GTDiff ()

@property (nonatomic, assign, readonly) git_diff_list *git_diff_list;

// A cache of the deltas for the diff. Will be populated only after the first
// call of -enumerateDeltasUsingBlock:.
@property (atomic, copy) NSArray *cachedDeltas;

@end

@implementation GTDiff

+ (int)handleParsedOptionsDictionary:(NSDictionary *)dictionary usingBlock:(int (^)(git_diff_options *optionsStruct))block {
	NSParameterAssert(block != nil);
	
	git_diff_options newOptions = GIT_DIFF_OPTIONS_INIT;
	
	NSNumber *flagsNumber = dictionary[GTDiffOptionsFlagsKey];
	if (flagsNumber != nil) newOptions.flags = (uint32_t)flagsNumber.unsignedIntegerValue;
	
	NSNumber *contextLinesNumber = dictionary[GTDiffOptionsContextLinesKey];
	if (contextLinesNumber != nil) newOptions.context_lines = (uint16_t)contextLinesNumber.unsignedIntegerValue;
	
	NSNumber *interHunkLinesNumber = dictionary[GTDiffOptionsInterHunkLinesKey];
	if (interHunkLinesNumber != nil) newOptions.interhunk_lines = (uint16_t)interHunkLinesNumber.unsignedIntegerValue;
	
	NSString *oldPrefix = dictionary[GTDiffOptionsOldPrefixKey];
	if (oldPrefix != nil) newOptions.old_prefix = oldPrefix.UTF8String;
	
	NSString *newPrefix = dictionary[GTDiffOptionsNewPrefixKey];
	if (newPrefix != nil) newOptions.new_prefix = newPrefix.UTF8String;
	
	NSNumber *maxSizeNumber = dictionary[GTDiffOptionsMaxSizeKey];
	if (maxSizeNumber != nil) newOptions.max_size = (uint16_t)maxSizeNumber.unsignedIntegerValue;
	
	NSArray *pathSpec = dictionary[GTDiffOptionsPathSpecArrayKey];
	if (pathSpec != nil) newOptions.pathspec = *pathSpec.git_strarray;

	git_diff_options *optionsPtr = &newOptions;
	if (dictionary.count < 1) optionsPtr = nil;

	return block(optionsPtr);
}

+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	NSParameterAssert(newTree == nil || [newTree.repository isEqual:repository]);
	NSParameterAssert(oldTree == nil || [oldTree.repository isEqual:repository]);
	
	__block git_diff_list *diffList;
	int returnValue = [self handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_tree_to_tree(&diffList, repository.git_repository, oldTree.git_tree, newTree.git_tree, optionsStruct);
	}];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue withAdditionalDescription:@"Failed to create diff between %@ and %@", oldTree.SHA, newTree.SHA];
		return nil;
	}
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffIndexFromTree:(GTTree *)tree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	NSParameterAssert(tree == nil || [tree.repository isEqual:repository]);

	__block git_diff_list *diffList;
	int returnValue = [self handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_tree_to_index(&diffList, repository.git_repository, tree.git_tree, NULL, optionsStruct);
	}];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue withAdditionalDescription:@"Failed to create diff between index and %@", tree.SHA];
		return nil;
	}
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffIndexToWorkingDirectoryInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	
	__block git_diff_list *diffList;
	int returnValue = [self handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_index_to_workdir(&diffList, repository.git_repository, NULL, optionsStruct);
	}];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue withAdditionalDescription:@"Failed to create diff between working directory and index"];
		return nil;
	}
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffWorkingDirectoryFromTree:(GTTree *)tree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	NSParameterAssert(tree == nil || [tree.repository isEqual:repository]);

	__block git_diff_list *diffList;
	int returnValue = [self handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_tree_to_workdir(&diffList, repository.git_repository, tree.git_tree, optionsStruct);
	}];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue withAdditionalDescription:@"Failed to create diff between working directory and %@", tree.SHA];
		return nil;
	}
	
	GTDiff *newDiff = [[GTDiff alloc] initWithGitDiffList:diffList];
	return newDiff;
}

+ (GTDiff *)diffWorkingDirectoryToHEADInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);

	GTCommit *HEADCommit = [repository lookupObjectByRefspec:@"HEAD" error:NULL];
	GTDiff *HEADIndexDiff = [GTDiff diffIndexFromTree:HEADCommit.tree inRepository:repository options:options error:error];
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
	if (_git_diff_list != NULL) {
		git_diff_list_free(_git_diff_list);
		_git_diff_list = NULL;
	}
}

- (void)enumerateDeltasUsingBlock:(void (^)(GTDiffDelta *delta, BOOL *stop))block {
	NSParameterAssert(block != nil);

	if (self.cachedDeltas == nil) {
		NSMutableArray *deltas = [NSMutableArray arrayWithCapacity:self.deltaCount];
		for (NSUInteger idx = 0; idx < self.deltaCount; idx ++) {
			git_diff_patch *patch;
			int result = git_diff_get_patch(&patch, NULL, self.git_diff_list, idx);
			if (result != GIT_OK) continue;
			
			GTDiffDelta *delta = [[GTDiffDelta alloc] initWithGitPatch:patch];
			if (delta == nil) continue;

			[deltas addObject:delta];
		}

		self.cachedDeltas = deltas;
	}

	[self.cachedDeltas enumerateObjectsUsingBlock:^(GTDiffDelta *delta, NSUInteger idx, BOOL *stop) {
		block(delta, stop);
	}];
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
	if (renameThresholdNumber != nil) newOptions->rename_threshold = renameThresholdNumber.unsignedShortValue;
	
	NSNumber *renameFromRewriteThresholdNumber = dictionary[GTDiffFindOptionsRenameFromRewriteThresholdKey];
	if (renameFromRewriteThresholdNumber != nil) newOptions->rename_from_rewrite_threshold = renameFromRewriteThresholdNumber.unsignedShortValue;
	
	NSNumber *copyThresholdNumber = dictionary[GTDiffFindOptionsCopyThresholdKey];
	if (copyThresholdNumber != nil) newOptions->copy_threshold = copyThresholdNumber.unsignedShortValue;
	
	NSNumber *breakRewriteThresholdNumber = dictionary[GTDiffFindOptionsBreakRewriteThresholdKey];
	if (renameThresholdNumber != nil) newOptions->break_rewrite_threshold = breakRewriteThresholdNumber.unsignedShortValue;
	
	NSNumber *renameLimitNumber = dictionary[GTDiffFindOptionsRenameLimitKey];
	if (renameLimitNumber != nil) newOptions->rename_limit = renameLimitNumber.unsignedShortValue;
	
	return YES;
}

- (void)findSimilarWithOptions:(NSDictionary *)options {
	git_diff_find_options findOptions = GIT_DIFF_FIND_OPTIONS_INIT;
	BOOL findOptionsCreated = [self findOptionsStructWithDictionary:options optionsStruct:&findOptions];
	git_diff_find_similar(self.git_diff_list, (findOptionsCreated ? &findOptions : NULL));
}

@end
