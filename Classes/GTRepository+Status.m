//
//  GTRepository+Status.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Status.h"
#import "GTConfiguration.h"
#import "GTStatusDelta.h"

#import "NSError+Git.h"
#import "NSArray+StringArray.h"

#import "EXTScope.h"

NSString *const GTRepositoryStatusOptionsShowKey = @"GTRepositoryStatusOptionsShow";
NSString *const GTRepositoryStatusOptionsFlagsKey = @"GTRepositoryStatusOptionsFlags";
NSString *const GTRepositoryStatusOptionsPathSpecArrayKey = @"GTRepositoryStatusOptionsPathSpecArray";

@implementation GTRepository (Status)

- (BOOL)enumerateFileStatusWithOptions:(NSDictionary *)options error:(NSError **)error usingBlock:(void (^)(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop))block {
	NSParameterAssert(block != NULL);
	
	__block git_status_options gitOptions = GIT_STATUS_OPTIONS_INIT;
	gitOptions.flags = GIT_STATUS_OPT_DEFAULTS;
	
	NSArray *pathSpec = options[GTRepositoryStatusOptionsPathSpecArrayKey];
	if (pathSpec != nil) gitOptions.pathspec = pathSpec.git_strarray;
		
	NSNumber *flagsNumber = options[GTRepositoryStatusOptionsFlagsKey];
	if (flagsNumber != nil) gitOptions.flags = flagsNumber.unsignedIntValue;
		
	NSNumber *showNumber = options[GTRepositoryStatusOptionsShowKey];
	if (showNumber != nil) gitOptions.show = showNumber.unsignedIntValue;
	
	git_status_list *statusList;
	int err = git_status_list_new(&statusList, self.git_repository, &gitOptions);
	@onExit {
		git_status_list_free(statusList);
		if (gitOptions.pathspec.count > 0) git_strarray_free(&gitOptions.pathspec);
	};
	
	if (err != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:err description:NSLocalizedString(@"Could not create status list.", nil)];
		return NO;
	}
	
	size_t statusCount = git_status_list_entrycount(statusList);
	if (statusCount < 1) return YES;
	
	BOOL stop = NO;
	for (size_t idx = 0; idx < statusCount; idx++) {
		const git_status_entry *entry = git_status_byindex(statusList, idx);
		GTStatusDelta *headToIndex = [[GTStatusDelta alloc] initWithGitDiffDelta:entry->head_to_index];
		GTStatusDelta *indexToWorkDir = [[GTStatusDelta alloc] initWithGitDiffDelta:entry->index_to_workdir];
		block(headToIndex, indexToWorkDir, &stop);
		
		if (stop) break;
	}
	
	return YES;
}

- (BOOL)isWorkingDirectoryClean {
	__block BOOL clean = YES;
	[self enumerateFileStatusWithOptions:nil error:NULL usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
		GTStatusDeltaStatus headToIndexStatus = headToIndex.status;
		GTStatusDeltaStatus indexToWorkDirStatus = indexToWorkingDirectory.status;
		
		// first, have items been deleted?
		if (indexToWorkDirStatus == GTStatusDeltaStatusDeleted || headToIndexStatus == GTStatusDeltaStatusDeleted) {
			clean = NO;
			*stop = YES;
		}
		
		// any untracked files?
		if (indexToWorkDirStatus == GTStatusDeltaStatusAdded) {
			clean = NO;
			*stop = YES;
		}
		
		// next, have items been modified?
		if (indexToWorkDirStatus == GTStatusDeltaStatusModified || headToIndexStatus == GTStatusDeltaStatusModified) {
			clean = NO;
			*stop = YES;
		}
	}];
	
	return clean;
}

- (GTFileStatusFlags)statusForFile:(NSString *)filePath success:(BOOL *)success error:(NSError **)error {
	NSParameterAssert(filePath != nil);

	git_status_t status;

	int gitError = git_status_file(&status, self.git_repository, filePath.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Status failed" failureReason:@"Failed to get status for file \"%@\" in \"%@\"", filePath, self.gitDirectoryURL];
		if (success != NULL) *success = NO;
		return GTFileStatusCurrent;
	}

	if (success != NULL) *success = YES;
	return (GTFileStatusFlags)status;
}

- (BOOL)shouldFileBeIgnored:(NSURL *)fileURL success:(BOOL *)success error:(NSError **)error {
	NSParameterAssert(fileURL != nil);

	int ignoreState = 0;

	int gitError = git_status_should_ignore(&ignoreState, self.git_repository, fileURL.path.fileSystemRepresentation);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Ignore failed" failureReason:@"Failed to get ignore status for file \"%@\" in \"%@\"", fileURL.path, self.gitDirectoryURL];
		if (success != NULL) *success = NO;
		return YES;
	}

	if (success != NULL) *success = YES;
	return (ignoreState == 0 ? YES : NO);
}

@end
