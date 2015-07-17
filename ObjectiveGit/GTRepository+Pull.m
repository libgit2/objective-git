//
//  GTRepository+Pull.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/17/15.
//  Copyright © 2015 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Pull.h"

#import "GTCommit.h"
#import "GTOID.h"
#import "GTRemote.h"
#import "GTReference.h"
#import "GTRepository+Committing.h"
#import "GTRepository+RemoteOperations.h"
#import "NSError+Git.h"
#import "git2/errors.h"

@implementation GTRepository (Pull)

#pragma mark - Pull

- (BOOL)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemoteFetchTransferProgressBlock)progressBlock
{
	NSParameterAssert(branch);
	NSParameterAssert(remote);

	GTRepository *repo = remote.repository;

	if (![self fetchRemote:remote withOptions:options error:error progress:progressBlock]) {
		return NO;
	}

	// Get remote branch after fetch so that it is up-to-date and doesn't need to be refreshed from disk
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
		// Local and remote tracking branch are already in sync
		return YES;
	}

	GTMergeAnalysis analysis = GTMergeAnalysisNone;
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
		NSString *message = [NSString stringWithFormat:@"merge %@/%@: Fast-forward", remote.name, remoteBranch.name];
		GTReference *reference = [localBranch.reference referenceByUpdatingTarget:remoteCommit.SHA message:message error:error];
		BOOL checkoutSuccess = [self checkoutReference:reference strategy:GTCheckoutStrategyForce error:error progressBlock:nil];

		return checkoutSuccess;
	} else if (analysis & GTMergeAnalysisNormal) {
		// Do normal merge
		GTTree *remoteTree = remoteCommit.tree;
		NSString *message = [NSString stringWithFormat:@"Merge branch '%@'", localBranch.shortName];
		NSArray *parents = @[ localCommit, remoteCommit ];
		GTCommit *mergeCommit = [repo createCommitWithTree:remoteTree message:message parents:parents updatingReferenceNamed:localBranch.name error:error];
		if (!mergeCommit) {
			return NO;
		}

		// TODO: Detect merge conflict

		BOOL success = [self checkoutReference:localBranch.reference strategy:GTCheckoutStrategyForce error:error progressBlock:nil];
		return success;
	}

	return NO;
}

- (BOOL)analyseMerge:(GTMergeAnalysis *)analysis fromBranch:(GTBranch *)fromBranch error:(NSError **)error
{
	NSParameterAssert(analysis != NULL);
	NSParameterAssert(fromBranch != nil);

	GTCommit *fromCommit = [fromBranch targetCommitWithError:error];
	if (!fromCommit) {
		return NO;
	}

	git_annotated_commit *annotatedCommit;

	// TODO: Check for lookup error
	git_annotated_commit_lookup(&annotatedCommit, self.git_repository, fromCommit.OID.git_oid);

	git_merge_preference_t preference = GIT_MERGE_PREFERENCE_NONE;

	// Merge analysis
	int gitError = git_merge_analysis((git_merge_analysis_t *)analysis, &preference, self.git_repository, (const git_annotated_commit **) &annotatedCommit, 1);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to analyze merge"];
		return NO;
	}

	// Cleanup
	git_annotated_commit_free(annotatedCommit);

	return YES;
}

@end
