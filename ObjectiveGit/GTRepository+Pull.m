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
#import "GTRepository+Committing.h"
#import "GTRepository+RemoteOperations.h"

@implementation GTRepository (Pull)

#pragma mark - Pull

- (BOOL)pullBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(NSDictionary *)options
                 error:(NSError **)error progress:(GTRemoteFetchTransferProgressBlock)progressBlock
{
    NSParameterAssert(branch);
    NSParameterAssert(remote);

    GTRepository *repo = remote.repository;

    GTBranch *remoteBranch;
    if (branch.branchType == GTBranchTypeLocal) {
        BOOL success;
        remoteBranch = [branch trackingBranchWithError:error success:&success];
        if (!success) {
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
    if (*error) {
        return NO;
    }

    GTCommit *localCommit = [localBranch targetCommitAndReturnError:error];
    if (*error) {
        return NO;
    }

    GTCommit *remoteCommit = [remoteBranch targetCommitAndReturnError:error];
    if (*error) {
        return NO;
    }

    if ([localCommit.SHA isEqualToString:remoteCommit.SHA]) {
        return YES;
    }

    // Merge
    GTTree *remoteTree = remoteCommit.tree;
    NSString *message = [NSString stringWithFormat:@"Merge branch '%@'", localBranch.shortName];
    NSArray *parents = @[ localCommit, remoteCommit ];
    GTCommit *mergeCommit = [repo createCommitWithTree:remoteTree message:message
                                               parents:parents updatingReferenceNamed:localBranch.name
                                                 error:error];
    if (!mergeCommit) {
        return NO;
    }

    return YES;
}

@end