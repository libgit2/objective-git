//
//  GTDiff.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 29/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiff.h"

#import "GTCommit.h"
#import "GTRepository.h"
#import "GTTree.h"

#import "NSArray+StringArray.h"
#import "NSError+Git.h"

#import "EXTScope.h"

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

@property (nonatomic, assign, readonly) git_diff *git_diff;

@property (nonatomic, strong, readonly) GTRepository *repository;

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
	git_strarray strArray = pathSpec.git_strarray;
	if (pathSpec != nil) newOptions.pathspec = strArray;
	@onExit {
		git_strarray_free((git_strarray *)&strArray);
	};

	git_diff_options *optionsPtr = &newOptions;
	if (dictionary.count < 1) optionsPtr = nil;

	return block(optionsPtr);
}

+ (instancetype)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	
	__block git_diff *diff;
	int status = [self handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_tree_to_tree(&diff, repository.git_repository, oldTree.git_tree, newTree.git_tree, optionsStruct);
	}];
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to create diff between %@ and %@", oldTree.SHA, newTree.SHA];
		return nil;
	}
	
	return [[self alloc] initWithGitDiff:diff repository:repository];
}

+ (instancetype)diffIndexFromTree:(GTTree *)tree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	NSParameterAssert(tree == nil || [tree.repository isEqual:repository]);

	__block git_diff *diff;
	int returnValue = [self handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_tree_to_index(&diff, repository.git_repository, tree.git_tree, NULL, optionsStruct);
	}];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create diff between index and %@", tree.SHA];
		return nil;
	}
	
	return [[self alloc] initWithGitDiff:diff repository:repository];
}

+ (instancetype)diffIndexToWorkingDirectoryInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	
	__block git_diff *diff;
	int returnValue = [self handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_index_to_workdir(&diff, repository.git_repository, NULL, optionsStruct);
	}];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create diff between working directory and index"];
		return nil;
	}
	
	return [[self alloc] initWithGitDiff:diff repository:repository];
}

+ (instancetype)diffWorkingDirectoryFromTree:(GTTree *)tree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);
	NSParameterAssert(tree == nil || [tree.repository isEqual:repository]);

	__block git_diff *diff;
	int returnValue = [self handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_tree_to_workdir(&diff, repository.git_repository, tree.git_tree, optionsStruct);
	}];
	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create diff between working directory and %@", tree.SHA];
		return nil;
	}
	
	return [[self alloc] initWithGitDiff:diff repository:repository];
}

+ (instancetype)diffWorkingDirectoryToHEADInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(repository != nil);

	GTCommit *HEADCommit = [[repository headReferenceWithError:NULL] resolvedTarget];
	GTDiff *HEADIndexDiff = [self diffIndexFromTree:HEADCommit.tree inRepository:repository options:options error:error];
	if (HEADIndexDiff == nil) return nil;

	GTDiff *WDDiff = [self diffIndexToWorkingDirectoryInRepository:repository options:options error:error];
	if (WDDiff == nil) return nil;

	git_diff_merge(HEADIndexDiff.git_diff, WDDiff.git_diff);

	return HEADIndexDiff;
}

- (instancetype)initWithGitDiff:(git_diff *)diff repository:(GTRepository *)repository {
	NSParameterAssert(diff != NULL);
	NSParameterAssert(repository != nil);
	
	self = [super init];
	if (self == nil) return nil;
	
	_git_diff = diff;
	_repository = repository;
	
	return self;
}

- (void)dealloc {
	if (_git_diff != NULL) {
		git_diff_free(_git_diff);
		_git_diff = NULL;
	}
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ deltaCount: %ld", super.debugDescription, (unsigned long)self.deltaCount];
}

- (void)enumerateDeltasUsingBlock:(void (^)(GTDiffDelta *delta, BOOL *stop))block {
	NSParameterAssert(block != nil);

	for (NSUInteger idx = 0; idx < self.deltaCount; idx ++) {
		GTDiffDelta *delta = [[GTDiffDelta alloc] initWithDiff:self deltaIndex:idx];
		if (delta == nil) continue;

		BOOL stop = NO;
		block(delta, &stop);
		if (stop) break;
	}
}

- (NSUInteger)deltaCount {
	return git_diff_num_deltas(self.git_diff);
}

- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType {
	return git_diff_num_deltas_of_type(self.git_diff, (git_delta_t)deltaType);
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
	git_diff_find_similar(self.git_diff, (findOptionsCreated ? &findOptions : NULL));
}

- (BOOL)mergeDiffWithDiff:(GTDiff *)diff error:(NSError **)error {
	int gitError = git_diff_merge(self.git_diff, diff.git_diff);
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Merging diffs failed"];
		return NO;
	}

	return YES;
}

@end
