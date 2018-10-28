//
//  GTUtilityFunctions.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/28/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

@import ObjectiveGit;
@import Nimble;
@import Quick;

#import "GTUtilityFunctions.h"

#pragma mark - Commit

CreateCommitBlock createCommitInRepository = ^ GTCommit * (NSString *message, NSData *fileData, NSString *fileName, GTRepository *repo) {
	GTReference *head = [repo headReferenceWithError:NULL];
	GTBranch *branch = [GTBranch branchWithReference:head];
	GTCommit *headCommit = [branch targetCommitWithError:NULL];

	GTTreeBuilder *treeBuilder = [[GTTreeBuilder alloc] initWithTree:headCommit.tree repository:repo error:nil];
	[treeBuilder addEntryWithData:fileData fileName:fileName fileMode:GTFileModeBlob error:nil];

	GTTree *testTree = [treeBuilder writeTree:nil];

	// We need the parent commit to make the new one
	GTReference *headReference = [repo headReferenceWithError:nil];
	GTCommit *parent = [repo lookUpObjectByOID:[headReference targetOID] objectType:GTObjectTypeCommit error:NULL];

	GTCommit *testCommit = [repo createCommitWithTree:testTree message:message parents:@[ parent ] updatingReferenceNamed:headReference.name error:nil];
	expect(testCommit).notTo(beNil());

	if (!repo.isBare) {
		git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
		opts.checkout_strategy = GIT_CHECKOUT_FORCE;
		int gitError = git_checkout_head(repo.git_repository, &opts);
		expect(gitError).to(equal(0));
	}

	return testCommit;
};

#pragma mark - Branch

BranchBlock localBranchWithName = ^ GTBranch * (NSString *branchName, GTRepository *repo) {
	BOOL success = NO;
	GTBranch *branch = [repo lookUpBranchWithName:branchName type:GTBranchTypeLocal success:&success error:NULL];
	expect(branch).notTo(beNil());
	expect(branch.shortName).to(equal(branchName));

	return branch;
};
