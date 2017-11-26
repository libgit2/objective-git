//
//  GTUtilityFunctions.m
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/28/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

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

	GTEnumerator *commitEnum = [[GTEnumerator alloc] initWithRepository:repo error:nil];
	[commitEnum pushSHA:[headReference targetOID].SHA error:nil];
	GTCommit *parent = [commitEnum nextObject];

	GTCommit *testCommit = [repo createCommitWithTree:testTree message:message parents:@[ parent ] updatingReferenceNamed:headReference.name error:nil];
	expect(testCommit).notTo(beNil());

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
