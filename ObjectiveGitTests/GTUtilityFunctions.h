//
//  GTUtilityFunctions.h
//  ObjectiveGitFramework
//
//  Created by Ben Chatelain on 6/28/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

@import Foundation;

@class GTBranch;
@class GTCommit;
@class GTRepository;

#pragma mark - Commit

typedef GTCommit *(^CreateCommitBlock)(NSString *message, NSData *fileData, NSString *fileName, GTRepository *repo);

// Helper to quickly create commits
extern CreateCommitBlock createCommitInRepository;

#pragma mark - Branch

typedef GTBranch *(^BranchBlock)(NSString *, GTRepository *);

// Helper to retrieve a branch by name
extern BranchBlock localBranchWithName;
