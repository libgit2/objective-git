//
//  GTRepository+Pull.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/17/15.
//  Copyright © 2015 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Pull.h"

#import "GTCommit.h"
#import "GTRemote.h"
#import "GTReference.h"
#import "GTRepository+Committing.h"
#import "GTRepository+RemoteOperations.h"

@implementation GTRepository (Pull)

#pragma mark - Pull

- (BOOL)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemoteFetchTransferProgressBlock)progressBlock
{
	NSParameterAssert(branch);
	NSParameterAssert(remote);

	GTRepository *repo = remote.repository;

	GTBranch *remoteBranch;
	if (branch.branchType == GTBranchTypeLocal) {
		BOOL success;
		remoteBranch = [branch trackingBranchWithError:error success:&success];
		if (!remoteBranch) {
			return NO;
		}
	}
	else {
		remoteBranch = branch;
	}

	if (![self fetchRemote:remote withOptions:options error:error progress:progressBlock]) {
		return NO;
	}

	// Check if merge is necessary
	GTBranch *localBranch = [repo currentBranchWithError:error];
	if (!localBranch) {
		return NO;
	}

	GTCommit *localCommit = [localBranch targetCommitWithError:error];
	if (!localCommit) {
		return NO;
	}

	GTCommit *remoteCommit = [remoteBranch targetCommitWithError:error];
	if (!remoteCommit) {
		return NO;
	}

	if ([localCommit.SHA isEqualToString:remoteCommit.SHA]) {
		return YES;
	}

	GTMergeAnalysis analysis;
	BOOL success = [self analyseMerge:&analysis fromBranch:remoteBranch error:error];
	if (!success) {
		return NO;
	}

	if (analysis & GTMergeAnalysisUpToDate) {
		// Nothing to do
		return YES;
	} else if (analysis & GTMergeAnalysisFastForward ||
			   analysis & GTMergeAnalysisUnborn) {
		// Fast-forward branch
		GTReference *reference = [localBranch.reference referenceByUpdatingTarget:remoteCommit.SHA message:nil error:error];
		BOOL checkoutSuccess = [self checkoutReference:reference strategy:GTCheckoutStrategyForce error:error progressBlock:nil];

		return checkoutSuccess;
	} else if (analysis & GTMergeAnalysisNormal) {
		// Do normal merge
		GTTree *remoteTree = remoteCommit.tree;
		NSString *message = [NSString stringWithFormat:@"Merge branch '%@'", localBranch.shortName];
		NSArray *parents = @[ localCommit, remoteCommit ];
		GTCommit *mergeCommit = [repo createCommitWithTree:remoteTree message:message parents:parents updatingReferenceNamed:localBranch.name error:error];

		[self checkoutReference:localBranch.reference strategy:GTCheckoutStrategyForce error:error progressBlock:nil];

		return mergeCommit != nil;
	}

	return NO;
}

- (BOOL)analyseMerge:(GTMergeAnalysis *)analysis fromBranch:(GTBranch *)fromBranch error:(NSError **)error
{
	git_merge_preference_t preference;
	git_annotated_commit *annotatedCommit;

	GTCommit *fromCommit = [fromBranch targetCommitWithError:error];
	if (!fromCommit) {
		return NO;
	}

	git_annotated_commit_lookup(&annotatedCommit, self.git_repository, git_object_id(fromCommit.git_object));
	git_merge_analysis((git_merge_analysis_t *)analysis, &preference, self.git_repository, (const git_annotated_commit **) &annotatedCommit, 1);
	git_annotated_commit_free(annotatedCommit);

	return YES;
}

@end
