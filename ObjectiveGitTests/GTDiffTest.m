//
//  GTDiffTest.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 04/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "Contants.h"

#import "GTDiff.h"
#import "GTDiffHunk.h"

@interface GTDiffTest : SenTestCase

@property (nonatomic, strong) GTRepository *repository;
@property (nonatomic, strong) GTCommit *firstCommit;
@property (nonatomic, strong) GTCommit *secondCommit;

@end

@implementation GTDiffTest

- (GTCommit *)findCommitWithSHA:(NSString *)sha {
	return (GTCommit *)[self.repository lookupObjectBySha:sha objectType:GTObjectTypeCommit error:NULL];
}

- (void)setUp {
	self.repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:NULL];
	STAssertNotNil(self.repository, @"Failed to initialise repository.");
	
	self.firstCommit = [self findCommitWithSHA:@"5b5b025afb0b4c913b4c338a42934a3863bf3644"];
	self.secondCommit = [self findCommitWithSHA:@"36060c58702ed4c2a40832c51758d5344201d89a"];
	STAssertNotNil(self.firstCommit, @"Could not find first commit to diff against");
	STAssertNotNil(self.secondCommit, @"Could not find second commit to diff against");
}

- (void)testInitialisation {
	GTTree *firstTree = self.firstCommit.tree;
	GTTree *secondTree = self.secondCommit.tree;
	GTDiff *treeDiff = [GTDiff diffOldTree:firstTree withNewTree:secondTree options:nil];
	STAssertNotNil(treeDiff, @"Unable to create a diff object with 2 trees.");
	
	GTDiff *indexDiff = [GTDiff diffIndexToTree:firstTree options:nil];
	STAssertNotNil(indexDiff, @"Unable to create a diff object with a tree to an index.");
	
	GTDiff *workingDirectoryToIndexDiff = [GTDiff diffWorkingDirectoryToIndexInRepository:self.repository options:nil];
	STAssertNotNil(workingDirectoryToIndexDiff, @"Unable to create a diff object of the index and working directory.");
	
	GTDiff *workingDirectoryToTreeDiff = [GTDiff diffWorkingDirectoryToTree:firstTree options:nil];
	STAssertNotNil(workingDirectoryToTreeDiff, @"Unable to create a diff with the working directory and a tree.");
}

- (void)testDeltaCreation {
	GTDiff *treeDiff = [GTDiff diffOldTree:self.firstCommit.tree withNewTree:self.secondCommit.tree options:nil];
	STAssertEquals(treeDiff.deltaCount, (NSUInteger)4, @"Incorrect delta count in diff.");
	STAssertEquals([treeDiff numberOfDeltasWithType:GTDiffFileDeltaAdded], (NSUInteger)4, @"Not correctly filtering delta typs.");
	
	
	NSArray *expectedChangeStrings = @[ @"hey", @"new file", @"hey", @"new file" ];
	__block NSUInteger index = 0;
	[treeDiff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
		STAssertEquals(delta.status, (GTDiffDeltaType)GTDiffFileDeltaAdded, @"Incorrect delta type,");
		for (GTDiffHunk *hunk in delta.hunks) {
			STAssertEquals(hunk.lineCount, (NSUInteger)1, @"Incorrect line count");
			STAssertEqualObjects(hunk.header, @"@@ -0,0 +1 @@", @"Incorrect hunk header");
			[hunk enumerateLinesInHunkUsingBlock:^(NSString *lineContent, NSUInteger oldLineNumber, NSUInteger newLineNumber, GTDiffHunkLineOrigin lineOrigin, BOOL *stop) {
				STAssertEqualObjects(lineContent, expectedChangeStrings[index], @"Incorrect diff line change content");
			}];
		}
		
		index ++; //:trollface:
	}];
}

@end
