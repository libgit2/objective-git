//
//  GTRepository+Pull.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/17/15.
//  Copyright © 2015 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Pull.h"

#import "GTCommit.h"
#import "GTRepository+RemoteOperations.h"
#import "NSError+Git.h"
#import "git2/errors.h"
#import "GTRepository+Merging.h"

NSString * const GTPullMergeConflictedFiles = @"GTPullMergeConflictedFiles";

@implementation GTRepository (Pull)

#pragma mark - Pull

- (BOOL)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemoteFetchTransferProgressBlock)progressBlock {
	NSParameterAssert(branch != nil);
	NSParameterAssert(remote != nil);

	GTRepository *repo = branch.repository;

	if (![self fetchRemote:remote withOptions:options error:error progress:progressBlock]) {
		return NO;
	}

	// Get tracking branch after fetch so that it is up-to-date and doesn't need to be refreshed from disk
	GTBranch *trackingBranch;
	if (branch.branchType == GTBranchTypeLocal) {
		BOOL success = NO;
		trackingBranch = [branch trackingBranchWithError:error success:&success];
		if (!success) {
			if (error != NULL) *error = [NSError git_errorFor:GIT_ERROR description:@"Tracking branch not found for %@", branch.name];
			return NO;
		}
		else if (!trackingBranch) {
			// Error should already be provided by libgit2
			return NO;
		}
	}
	else {
		// When given a remote branch, use it as the tracking branch
		trackingBranch = branch;
	}

	return [repo mergeBranchIntoCurrentBranch:trackingBranch withError:error];
}

@end
