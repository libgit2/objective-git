//
//  GTDiffSpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 17/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

SpecBegin(GTDiff)

__block GTRepository *repository = nil;

describe(@"GTDiff initialisation", ^{
	__block GTCommit *firstCommit = nil;
	__block GTCommit *secondCommit = nil;
	
	beforeEach(^{
		repository = self.testAppFixtureRepository;
		expect(repository).toNot.beNil();
		
		firstCommit = (GTCommit *)[repository lookUpObjectBySHA:@"8e0e65988d3007867a9f59ca8639ba975ef97e69" objectType:GTObjectTypeCommit error:NULL];
		expect(firstCommit).toNot.beNil();
		
		secondCommit = (GTCommit *)[repository lookUpObjectBySHA:@"a5840674db1a58cac0b2e7d046b627837a16f217" objectType:GTObjectTypeCommit error:NULL];
		expect(secondCommit).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff from 2 trees", ^{
		expect([GTDiff diffOldTree:firstCommit.tree withNewTree:secondCommit.tree inRepository:repository options:nil error:NULL]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against an empty tree", ^{
		expect([GTDiff diffOldTree:nil withNewTree:firstCommit.tree inRepository:repository options:nil error:NULL]).toNot.beNil();
		expect([GTDiff diffOldTree:firstCommit.tree withNewTree:nil inRepository:repository options:nil error:NULL]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against the index with a tree", ^{
		expect([GTDiff diffIndexFromTree:secondCommit.tree inRepository:repository options:nil error:NULL]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against the index without a tree", ^{
		expect([GTDiff diffIndexFromTree:nil inRepository:repository options:nil error:NULL]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against a working directory and a tree", ^{
		expect([GTDiff diffWorkingDirectoryFromTree:firstCommit.tree inRepository:repository options:nil error:NULL]).toNot.beNil();
	});
	
	it(@"should be able to initialise a diff against a working directory and an empty tree", ^{
		expect([GTDiff diffWorkingDirectoryFromTree:nil inRepository:repository options:nil error:NULL]).toNot.beNil();
	});
	
	it(@"should be able to initialse a diff against an index from a repo's working directory", ^{
		expect([GTDiff diffIndexToWorkingDirectoryInRepository:repository options:nil error:NULL]).toNot.beNil();
	});

	it(@"should be able to initialize a diff between HEAD and the working directory", ^{
		expect([GTDiff diffWorkingDirectoryToHEADInRepository:repository options:nil error:NULL]).notTo.beNil();
	});
});

describe(@"GTDiff diffing", ^{
	__block GTCommit *firstCommit = nil;
	__block GTCommit *secondCommit = nil;
	__block GTDiff *diff = nil;
	__block void (^setupDiffFromCommitSHAsAndOptions)(NSString *, NSString *, NSDictionary *) = nil;
	
	beforeEach(^{
		repository = self.testAppFixtureRepository;
		expect(repository).toNot.beNil();
		
		setupDiffFromCommitSHAsAndOptions = [^(NSString *firstCommitSHA, NSString *secondCommitSHA, NSDictionary *options) {
			firstCommit = (GTCommit *)[repository lookUpObjectBySHA:firstCommitSHA objectType:GTObjectTypeCommit error:NULL];
			expect(firstCommit).toNot.beNil();
			secondCommit = (GTCommit *)[repository lookUpObjectBySHA:secondCommitSHA objectType:GTObjectTypeCommit error:NULL];
			expect(secondCommit).toNot.beNil();
			
			diff = [GTDiff diffOldTree:firstCommit.tree withNewTree:secondCommit.tree inRepository:repository options:options error:NULL];
			expect(diff).toNot.beNil();
		} copy];
	});
		
	it(@"should be able to diff simple file changes", ^{
		setupDiffFromCommitSHAsAndOptions(@"be0f001ff517a00b5b8e3c29ee6561e70f994e17", @"fe89ea0a8e70961b8a6344d9660c326d3f2eb0fe", nil);

		expect(diff.deltaCount).to.equal(1);
		expect([diff numberOfDeltasWithType:GTDiffFileDeltaModified]).to.equal(1);
		
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			NSError *error = nil;
			GTDiffPatch *patch = [delta generatePatch:&error];
			expect(patch).notTo.beNil();
			expect(error).to.beNil();

			expect(delta.oldFile.path).to.equal(@"TestAppWindowController.h");
			expect(delta.oldFile.path).to.equal(delta.newFile.path);
			expect(delta.flags & GTDiffFileFlagBinaryMask).to.equal(GTDiffFileFlagNotBinary);
			expect(delta.type).to.equal(GTDiffFileDeltaModified);

			expect(patch.delta).to.beIdenticalTo(delta);
			expect(patch.hunkCount).to.equal(1);
			expect(patch.addedLinesCount).to.equal(1);
			expect(patch.deletedLinesCount).to.equal(1);
			expect(patch.contextLinesCount).to.equal(6);

			[patch enumerateHunksUsingBlock:^(GTDiffHunk *hunk, BOOL *stop) {
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
				[hunk enumerateLinesInHunk:NULL usingBlock:^(GTDiffLine *line, BOOL *stop) {
					expect(line.content).to.equal(expectedLines[lineIndex]);
					if (lineIndex == subtractionLine) {
						expect((NSUInteger)line.origin).to.equal(GTDiffLineOriginDeletion);
					} else if (lineIndex == additionLine) {
						expect((NSUInteger)line.origin).to.equal(GTDiffLineOriginAddition);
					} else {
						expect((NSUInteger)line.origin).to.equal(GTDiffLineOriginContext);
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
		setupDiffFromCommitSHAsAndOptions(@"4d5a6cc7a4d810be71bd47331c947b22580a5997", @"38f1e536cfc2ee41e07d55b38baec00149b2b0d1", nil);

		expect(diff.deltaCount).to.equal(1);
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			expect(delta.newFile.path).to.equal(@"REAME"); //loltypo
			expect(delta.type).to.equal(GTDiffFileDeltaAdded);

			*stop = YES;
		}];
	});
	
	it(@"should recognise deleted files", ^{
		setupDiffFromCommitSHAsAndOptions(@"6317779b4731d9c837dcc6972b964bdf4211eeef", @"9f90c6e24629fae3ef51101bb6448342b44098ef", nil);

		expect(diff.deltaCount).to.equal(1);
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			expect(delta.type).to.equal(GTDiffFileDeltaDeleted);

			*stop = YES;
		}];
	});
	
	it(@"should recognise binary files", ^{
		setupDiffFromCommitSHAsAndOptions(@"2ba9cdca982ac35a8db29f51c635251374008229", @"524500582248889ef2243931aa7fc48aa21dd12f", nil);

		expect(diff.deltaCount).to.equal(1);
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			// Determine binary/not binary status.
			[delta generatePatch:NULL];

			expect(delta.flags & GTDiffFileFlagBinaryMask).to.equal(GTDiffFileFlagBinary);

			*stop = YES;
		}];
		
	});
	
	it(@"should recognise renames", ^{
		setupDiffFromCommitSHAsAndOptions(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0", @"6b0c1c8b8816416089c534e474f4c692a76ac14f", nil);
		[diff findSimilarWithOptions:nil];

		expect(diff.deltaCount).to.equal(1);
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			expect(delta.type).to.equal(GTDiffFileDeltaRenamed);
			expect(delta.oldFile.path).to.equal(@"README");
			expect(delta.newFile.path).to.equal(@"README_renamed");

			*stop = YES;
		}];
	});
	
	it(@"should correctly pass options to libgit2", ^{
		NSDictionary *options = @{ GTDiffOptionsContextLinesKey: @(5) };
		setupDiffFromCommitSHAsAndOptions(@"be0f001ff517a00b5b8e3c29ee6561e70f994e17", @"fe89ea0a8e70961b8a6344d9660c326d3f2eb0fe", options);

		expect(diff.deltaCount).to.equal(1);
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			NSError *error = nil;
			GTDiffPatch *patch = [delta generatePatch:&error];
			expect(patch).notTo.beNil();
			expect(error).to.beNil();

			expect(patch.hunkCount).to.equal(1);
			expect(patch.delta).to.beIdenticalTo(delta);

			[patch enumerateHunksUsingBlock:^(GTDiffHunk *hunk, BOOL *stop) {
				__block NSUInteger contextCount = 0;
				[hunk enumerateLinesInHunk:NULL usingBlock:^(GTDiffLine *line, BOOL *stop) {
					if (line.origin == GTDiffLineOriginContext) contextCount ++;
				}];
				expect(contextCount).to.equal(10);
				*stop = YES;
			}];

			*stop = YES;
		}];
	});
	
	it(@"should correctly limit itself to a given pathspec", ^{
		NSDictionary *options = @{ GTDiffOptionsPathSpecArrayKey: @[ @"ladflbahjgdf" ] };
		setupDiffFromCommitSHAsAndOptions(@"be0f001ff517a00b5b8e3c29ee6561e70f994e17", @"fe89ea0a8e70961b8a6344d9660c326d3f2eb0fe", options);
		expect(diff.deltaCount).to.equal(0);
		
		options = @{ GTDiffOptionsPathSpecArrayKey: @[ @"TestAppWindowController.h" ] };
		setupDiffFromCommitSHAsAndOptions(@"be0f001ff517a00b5b8e3c29ee6561e70f994e17", @"fe89ea0a8e70961b8a6344d9660c326d3f2eb0fe", options);
		expect(diff.deltaCount).to.equal(1);
	});
	
	it(@"should correctly recognise binary and text files", ^{
		setupDiffFromCommitSHAsAndOptions(@"6b0c1c8b8816416089c534e474f4c692a76ac14f", @"a4bca6b67a5483169963572ee3da563da33712f7", nil);
		expect(diff.deltaCount).to.equal(3);
		
		NSDictionary *expectedBinaryness = @{ @"README.md": @(NO), @"hero_slide1.png": @(YES), @"jquery-1.8.1.min.js": @(NO) };
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			// Determine binary/not binary status.
			[delta generatePatch:NULL];

			if ([expectedBinaryness[delta.newFile.path] boolValue]) {
				expect(delta.flags & GTDiffFileFlagBinaryMask).to.equal(GTDiffFileFlagBinary);
			} else {
				expect(delta.flags & GTDiffFileFlagBinaryMask).to.equal(GTDiffFileFlagNotBinary);
			}
		}];
	});
	
	it(@"shouldn't choke on totally cray diffs", ^{
		setupDiffFromCommitSHAsAndOptions(@"6b0c1c8b8816416089c534e474f4c692a76ac14f", @"a4bca6b67a5483169963572ee3da563da33712f7", nil);
		
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			if (![delta.newFile.path isEqualToString:@"jquery-1.8.1.min.js"]) return;

			NSError *error = nil;
			GTDiffPatch *patch = [delta generatePatch:&error];
			expect(patch).notTo.beNil();
			expect(error).to.beNil();
			
			expect(patch.hunkCount).to.equal(1);
			expect(patch.delta).to.beIdenticalTo(delta);

			[patch enumerateHunksUsingBlock:^(GTDiffHunk *hunk, BOOL *stop) {
				expect(hunk.lineCount).to.equal(3);
				*stop = YES;
			}];
			
			*stop = YES;
		}];
	});
	
	it(@"should correctly find untracked files if asked", ^{
		diff = [GTDiff diffIndexToWorkingDirectoryInRepository:repository options:@{ GTDiffOptionsFlagsKey: @(GTDiffOptionsFlagsIncludeUntracked) } error:NULL];

		__block BOOL foundImage = NO;
		[diff enumerateDeltasUsingBlock:^(GTDiffDelta *delta, BOOL *stop) {
			if (![delta.newFile.path isEqualToString:@"UntrackedImage.png"]) return;

			foundImage = YES;			
			*stop = YES;
		}];
		
		expect(foundImage).to.beTruthy();
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
