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
	GTBranch *branch = [GTBranch branchWithReference:head repository:repo];
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
	NSString *reference = [GTBranch.localNamePrefix stringByAppendingString:branchName];
	NSArray *branches = [repo branchesWithPrefix:reference error:NULL];
	expect(branches).notTo(beNil());
	expect(@(branches.count)).to(equal(@1));
	expect(((GTBranch *)branches[0]).shortName).to(equal(branchName));

	return branches[0];
};
