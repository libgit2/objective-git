//
//  GTRepository+Status.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Status.h"

#import "GTStatusDelta.h"

#import "NSArray+StringArray.h"

NSString *const GTRepositoryStatusOptionsShowKey = @"GTRepositoryStatusOptionsShow";
NSString *const GTRepositoryStatusOptionsFlagsKey = @"GTRepositoryStatusOptionsFlags";
NSString *const GTRepositoryStatusOptionsPathSpecArrayKey = @"GTRepositoryStatusOptionsPathSpecArray";

@implementation GTRepository (Status)

- (void)enumerateFileStatusWithOptions:(NSDictionary *)options usingBlock:(void(^)(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop))block {
	NSParameterAssert(block != NULL);
	
	git_status_options gitOptions = GIT_STATUS_OPTIONS_INIT;
	gitOptions.flags = GIT_STATUS_OPT_DEFAULTS;
	
	NSArray *pathSpec = options[GTRepositoryStatusOptionsPathSpecArrayKey];
	if (pathSpec != nil) gitOptions.pathspec = *[pathSpec git_strarray];
		
	NSNumber *flagsNumber = options[GTRepositoryStatusOptionsFlagsKey];
	if (flagsNumber != nil) gitOptions.flags = flagsNumber.unsignedIntValue;
		
	NSNumber *showNumber = options[GTRepositoryStatusOptionsShowKey];
	if (showNumber != nil) gitOptions.show = showNumber.unsignedIntValue;
	
	git_status_list *statusList;
	int error = git_status_list_new(&statusList, self.git_repository, &gitOptions);
	if (error != GIT_OK) return; //?
	
	size_t statusCount = git_status_list_entrycount(statusList);
	if (statusCount < 1) return;
	
	BOOL stop = NO;
	for (size_t idx = 0; idx < statusCount; idx ++) {
		const git_status_entry *entry = git_status_byindex(statusList, idx);
		GTStatusDelta *headToIndex = [[GTStatusDelta alloc] initWithGitDiffDelta:entry->head_to_index];
		GTStatusDelta *indexToWorkDir = [[GTStatusDelta alloc] initWithGitDiffDelta:entry->index_to_workdir];
		block(headToIndex, indexToWorkDir, &stop);
		
		if (stop) break;
	}
	
	git_status_list_free(statusList);
	git_strarray_free(&gitOptions.pathspec);
}

- (BOOL)isWorkingDirectoryClean {
	__block BOOL clean = YES;
	[self enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
		GTStatusDeltaStatus headToIndexStatus = headToIndex.status;
		GTStatusDeltaStatus indexToWorkDirStatus = indexToWorkingDirectory.status;
		
		// first, have items been deleted?
		// (not sure why we would get WT_DELETED AND INDEX_NEW in this situation, but that's what I got experimentally. WD-rpw, 02-23-2012
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

@end
