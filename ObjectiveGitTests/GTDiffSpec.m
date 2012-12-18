//
//  GTDiffSpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 17/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "Contants.h"

SpecBegin(GTDiff)

__block GTRepository *repository = nil;

describe(@"GTDiff initialisation", ^{
	__block GTCommit *firstCommit = nil;
	__block GTCommit *secondCommit = nil;
	
	beforeEach(^{
		repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:NULL];
		expect(repository).toNot.beNil();
		
		firstCommit = (GTCommit *)[repository lookupObjectBySha:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" objectType:GTObjectTypeCommit error:NULL];
		expect(firstCommit).toNot.beNil();
		
		secondCommit = (GTCommit *)[repository lookupObjectBySha:@"36060c58702ed4c2a40832c51758d5344201d89a" objectType:GTObjectTypeCommit error:NULL];
		expect(secondCommit).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff from 2 trees", ^{
		expect([GTDiff diffOldTree:firstCommit.tree withNewTree:secondCommit.tree options:nil]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against the index with a tree", ^{
		expect([GTDiff diffIndexToTree:secondCommit.tree options:nil]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against a working directory and a tree", ^{
		expect([GTDiff diffWorkingDirectoryFromTree:firstCommit.tree options:nil]).toNot.beNil();
	});
	
	it(@"should be able to initialse a diff against an index from a repo's working directory", ^{
		expect([GTDiff diffWorkingDirectoryToIndexInRepository:repository options:nil]).toNot.beNil();
	});
});

describe(@"GTDiff diffing", ^{
	__block GTCommit *firstCommit = nil;
	__block GTCommit *secondCommit = nil;
	__block GTDiff *diff = nil;
	
	beforeEach(^{
		repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_APP_REPO_PATH(self.class)] error:NULL];
		expect(repository).toNot.beNil();
	});
	
	void (^setupDiffFromCommitSHAs)(NSString *, NSString *) = [^(NSString *firstCommitSHA, NSString *secondCommitSHA) {
		firstCommit = (GTCommit *)[repository lookupObjectBySha:firstCommitSHA objectType:GTObjectTypeCommit error:NULL];
		expect(firstCommit).toNot.beNil();
		secondCommit = (GTCommit *)[repository lookupObjectBySha:secondCommitSHA objectType:GTObjectTypeCommit error:NULL];
		expect(secondCommit).toNot.beNil();
		
		diff = [GTDiff diffOldTree:firstCommit.tree withNewTree:secondCommit.tree options:nil];
		expect(diff).toNot.beNil();
	} copy];
	
	it(@"should be able to diff simple file changes", ^{
		setupDiffFromCommitSHAs(@"be0f001ff517a00b5b8e3c29ee6561e70f994e17", @"fe89ea0a8e70961b8a6344d9660c326d3f2eb0fe");
		expect(diff.deltaCount).to.equal(1);
		expect([diff numberOfDeltasWithType:GTDiffFileDeltaModified]).to.equal(1);
		
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			expect(delta.oldFile.path).to.equal(@"TestAppWindowController.h");
			expect(delta.oldFile.path).to.equal(delta.newFile.path);
			expect(delta.hunkCount).to.equal(1);
			expect(delta.binary).to.beFalsy();
			expect((NSUInteger)delta.type).to.equal(GTDiffFileDeltaModified);
			
			[delta enumerateHunksWithBlock:^(GTDiffHunk *hunk, BOOL *stop) {
				expect(hunk.header).to.equal(@"@@ -4,7 +4,7 @@");
				expect(hunk.lineCount).to.equal(8);
				
				NSArray *expectedLines = @[ @"//",
				@"//  Created by Joe Ricioppo on 9/29/10.",
				@"//  Copyright 2010 __MyCompanyName__. All rights reserved.",
				@"//",
				@"// duuuuuuuude",
				@"",
				@"#import <Cocoa/Cocoa.h>",
				@"#import <BWToolkitFramework/BWToolkitFramework.h>" ];
				
				NSUInteger subtractionLine = 3;
				NSUInteger additionLine = 4;
				__block NSUInteger lineIndex = 0;
				[hunk enumerateLinesInHunkUsingBlock:^(NSString *lineContent, NSUInteger oldLineNumber, NSUInteger newLineNumber, GTDiffHunkLineOrigin lineOrigin, BOOL *stop) {
					expect(lineContent).to.equal(expectedLines[lineIndex]);
					if (lineIndex == subtractionLine) {
						expect((NSUInteger)lineOrigin).to.equal(GTDiffHunkLineOriginDeletion);
					} else if (lineIndex == additionLine) {
						expect((NSUInteger)lineOrigin).to.equal(GTDiffHunkLineOriginAddition);
					} else {
						expect((NSUInteger)lineOrigin).to.equal(GTDiffHunkLineOriginContext);
					}
					
					lineIndex ++;
				}];
			}];
			
			// just in case we have failed an above test, don't add a whole bunch
			// more false failures by iterating again.
			*stop = YES;
		}];
	});
	
	it(@"should recognised added files", ^{
		setupDiffFromCommitSHAs(@"4d5a6cc7a4d810be71bd47331c947b22580a5997", @"38f1e536cfc2ee41e07d55b38baec00149b2b0d1");
		expect(diff.deltaCount).to.equal(1);
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			expect(delta.newFile.path).to.equal(@"REAME"); //loltypo
			expect((NSUInteger)delta.type).to.equal(GTDiffFileDeltaAdded);
			*stop = YES;
		}];
	});
	
	it(@"should recognise deleted files", ^{
		setupDiffFromCommitSHAs(@"6317779b4731d9c837dcc6972b964bdf4211eeef", @"9f90c6e24629fae3ef51101bb6448342b44098ef");
		expect(diff.deltaCount).to.equal(1);
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			expect((NSUInteger)delta.type).to.equal(GTDiffFileDeltaDeleted);
			*stop = YES;
		}];
	});
	
	it(@"should recognise binary files", ^{
		setupDiffFromCommitSHAs(@"2ba9cdca982ac35a8db29f51c635251374008229", @"524500582248889ef2243931aa7fc48aa21dd12f");
		expect(diff.deltaCount).to.equal(1);
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			expect(delta.binary).to.beTruthy();
			*stop = YES;
		}];
		
	});
});

SpecEnd
