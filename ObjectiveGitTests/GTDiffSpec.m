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
__block GTCommit *firstCommit = nil;
__block GTCommit *secondCommit = nil;

describe(@"GTDiff initialisation", ^{
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
		expect([GTDiff diffWorkingDirectoryToTree:firstCommit.tree options:nil]).toNot.beNil();
	});
	
	it(@"should be able to initialse a diff against an index from a repo's working directory", ^{
		expect([GTDiff diffWorkingDirectoryToIndexInRepository:repository options:nil]).toNot.beNil();
	});
});

describe(@"GTDiff diffing", ^{
	beforeEach(^{
		repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_APP_REPO_PATH(self.class)] error:NULL];
		expect(repository).toNot.beNil();
	});
	
	it(@"should be able to diff simple file changes", ^{
		GTCommit *firstCommit = (GTCommit *)[repository lookupObjectBySha:@"be0f001ff517a00b5b8e3c29ee6561e70f994e17" objectType:GTObjectTypeCommit error:NULL];
		expect(firstCommit).toNot.beNil();
		GTCommit *secondCommit = (GTCommit *)[repository lookupObjectBySha:@"fe89ea0a8e70961b8a6344d9660c326d3f2eb0fe" objectType:GTObjectTypeCommit error:NULL];
		expect(secondCommit).toNot.beNil();
		
		GTDiff *diff = [GTDiff diffOldTree:firstCommit.tree withNewTree:secondCommit.tree options:nil];
		expect(diff).toNot.beNil();
		expect(diff.deltaCount).to.equal(1);
		expect([diff numberOfDeltasWithType:GTDiffFileDeltaModified]).to.equal(1);
		
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			expect(delta.oldFile.path).to.equal(@"TestAppWindowController.h");
			expect(delta.oldFile.path).to.equal(delta.newFile.path);
			expect(delta.hunkCount).to.equal(1);
			expect(delta.isBinary).to.beFalsy();
			expect((NSUInteger)delta.status).to.equal(GTDiffFileDeltaModified);
			
			for (GTDiffHunk *hunk in delta.hunks) {
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
			}
			
		 // just in case we have failed an above test, don't add a whole bunch
		 // more false failures by iterating again.
		 *stop = YES;
		}];
	});
});

SpecEnd
