//
//  GTIndexSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 5/10/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTIndex.h"
#import "GTConfiguration.h"

SpecBegin(GTIndex)

__block GTRepository *repository;
__block GTIndex *index;

beforeEach(^{
	repository = self.testAppFixtureRepository;

	index = [repository indexWithError:NULL];
	expect(index).notTo.beNil();

	BOOL success = [index refresh:NULL];
	expect(success).to.beTruthy();
});

it(@"should count the entries", ^{
	expect(index.entryCount).to.equal(24);
});

it(@"should clear all entries", ^{
	[index clear:NULL];
	expect(index.entryCount).to.equal(0);
});

it(@"should read entry properties", ^{
	GTIndexEntry *entry = [index entryAtIndex:0];
	expect(entry).notTo.beNil();
	expect(entry.path).to.equal(@".gitignore");
	expect(entry.staged).to.beFalsy();
});

it(@"should write to the repository and return a tree", ^{
	GTTree *tree = [index writeTree:NULL];
	expect(tree).notTo.beNil();
	expect(tree.entryCount).to.equal(23);
	expect(tree.repository).to.equal(repository);
});

it(@"should write to a specific repository and return a tree", ^{
	GTRepository *repository = self.bareFixtureRepository;
	NSArray *branches = [repository allBranchesWithError:NULL];
	GTCommit *masterCommit = [branches[0] targetCommitAndReturnError:NULL];
	GTCommit *packedCommit = [branches[1] targetCommitAndReturnError:NULL];

	expect(masterCommit).notTo.beNil();
	expect(packedCommit).notTo.beNil();

	GTIndex *index = [masterCommit.tree merge:packedCommit.tree ancestor:NULL error:NULL];
	GTTree *mergedTree = [index writeTreeToRepository:repository error:NULL];

	expect(index).notTo.beNil();
	expect(mergedTree).notTo.beNil();
	expect(mergedTree.entryCount).to.equal(5);
	expect(mergedTree.repository).to.equal(repository);
});

it(@"should create an index in memory", ^{
	GTIndex *memoryIndex = [GTIndex inMemoryIndexWithRepository:repository error:NULL];
	expect(memoryIndex).notTo.beNil();
	expect(memoryIndex.fileURL).to.beNil();
});

it(@"should add the contents of a tree", ^{
	GTCommit *headCommit = [repository lookUpObjectByRevParse:@"HEAD" error:NULL];
	expect(headCommit).notTo.beNil();

	GTTree *headTree = headCommit.tree;
	expect(headTree.entryCount).to.beGreaterThan(0);

	GTIndex *memoryIndex = [GTIndex inMemoryIndexWithRepository:index.repository error:NULL];
	expect(memoryIndex).notTo.beNil();
	expect(memoryIndex.entryCount).to.equal(0);

	BOOL success = [memoryIndex addContentsOfTree:headTree error:NULL];
	expect(success).to.beTruthy();

	[headTree enumerateEntriesWithOptions:GTTreeEnumerationOptionPre error:NULL block:^(GTTreeEntry *treeEntry, NSString *root, BOOL *stop) {
		if (treeEntry.type == GTObjectTypeBlob) {
			NSString *path = [root stringByAppendingString:treeEntry.name];

			GTIndexEntry *indexEntry = [memoryIndex entryWithName:path];
			expect(indexEntry).notTo.beNil();
		}

		return YES;
	}];
});

describe(@"conflict enumeration", ^{
	it(@"should correctly find no conflicts", ^{
		expect(index.hasConflicts).to.beFalsy();
	});

	it(@"should immediately return YES when enumerating no conflicts", ^{
		__block BOOL blockRan = NO;
		BOOL enumerationResult = [index enumerateConflictedFilesWithError:NULL usingBlock:^(GTIndexEntry *ancestor, GTIndexEntry *ours, GTIndexEntry *theirs, BOOL *stop) {
			blockRan = YES;
		}];
		expect(enumerationResult).to.beTruthy();
		expect(blockRan).to.beFalsy();
	});

	it(@"should correctly report conflicts", ^{
		index = [self.conflictedFixtureRepository indexWithError:NULL];
		expect(index).notTo.beNil();
		expect(index.hasConflicts).to.beTruthy();
	});

	it(@"should enumerate conflicts successfully", ^{
		index = [self.conflictedFixtureRepository indexWithError:NULL];
		expect(index).notTo.beNil();

		NSError *err = NULL;
		__block NSUInteger count = 0;
		NSArray *expectedPaths = @[ @"TestAppDelegate.h", @"main.m" ];
		BOOL enumerationResult = [index enumerateConflictedFilesWithError:&err usingBlock:^(GTIndexEntry *ancestor, GTIndexEntry *ours, GTIndexEntry *theirs, BOOL *stop) {
			expect(ours.path).to.equal(expectedPaths[count]);
			count ++;
		}];

		expect(enumerationResult).to.beTruthy();
		expect(err).to.beNil();
		expect(count).to.equal(2);
	});
});

describe(@"updating pathspecs", ^{
	NSString *fileName = @"REAME_";
	beforeEach(^{
		index = [self.testAppFixtureRepository indexWithError:NULL];
		NSString *filePath = [self.testAppFixtureRepository.fileURL.path stringByAppendingPathComponent:fileName];
		[@"The wild west..." writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:NULL];

		expect(index).toNot.beNil();
		expect([index.repository statusForFile:fileName success:NULL error:NULL]).to.equal(GTFileStatusModifiedInWorktree);
	});

	it(@"should update the Index", ^{
		BOOL success = [index updatePathspecs:@[ fileName ] error:NULL passingTest:^(NSString *matchedPathspec, NSString *path, BOOL *stop) {
			expect(matchedPathspec).to.equal(fileName);
			expect(path).to.equal(fileName);
			return YES;
		}];

		expect(success).to.beTruthy();
		expect([index.repository statusForFile:fileName success:NULL error:NULL]).to.equal(GTFileStatusModifiedInIndex);
	});

	it(@"should skip a specific file", ^{
		BOOL success = [index updatePathspecs:NULL error:NULL passingTest:^(NSString *matchedPathspec, NSString *path, BOOL *stop) {
			if ([path.lastPathComponent isEqualToString:fileName]) {
				return NO;
			} else {
				return YES;
			}
		}];

		expect(success).to.beTruthy();
		expect([index.repository statusForFile:fileName success:NULL error:NULL]).to.equal(GTFileStatusModifiedInWorktree);
	});

	it(@"should stop be able to stop early", ^{
		NSString *otherFileName = @"TestAppDelegate.h";
		[@"WELP" writeToFile:[self.testAppFixtureRepository.fileURL.path stringByAppendingPathComponent:otherFileName] atomically:NO encoding:NSUTF8StringEncoding error:NULL];
		BOOL success = [index updatePathspecs:NULL error:NULL passingTest:^(NSString *matchedPathspec, NSString *path, BOOL *stop) {
			if ([path.lastPathComponent isEqualToString:fileName]) {
				*stop = YES;
				return YES;
			}
			return YES;
		}];

		expect(success).to.beTruthy();
		expect([index.repository statusForFile:fileName success:NULL error:NULL]).to.equal(GTFileStatusModifiedInIndex);
		expect([index.repository statusForFile:otherFileName success:NULL error:NULL]).equal(GTFileStatusModifiedInWorktree);
	});
});

describe(@"adding files", ^{
	__block GTRepository *repo;
	__block GTConfiguration *configuration;
	__block GTIndex *index;
	__block NSURL *fileURL;
	__block NSURL *renamedFileURL;

	NSString *filename = @"Åströmm";
	NSString *renamedFilename = [filename stringByAppendingString:filename];

	NSDictionary *renamedOptions = @{ GTRepositoryStatusOptionsFlagsKey: @(GTRepositoryStatusFlagsIncludeIgnored | GTRepositoryStatusFlagsIncludeUntracked | GTRepositoryStatusFlagsRecurseUntrackedDirectories | GTRepositoryStatusFlagsRenamesHeadToIndex | GTRepositoryStatusFlagsIncludeUnmodified) };

	BOOL (^fileStatusEqualsExpected)(NSString *filename, GTStatusDeltaStatus headToIndexStatus, GTStatusDeltaStatus indexToWorkingDirectoryStatus) = ^(NSString *filename, GTStatusDeltaStatus headToIndexStatus, GTStatusDeltaStatus indexToWorkingDirectoryStatus) {
		return [index.repository enumerateFileStatusWithOptions:renamedOptions error:NULL usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![headToIndex.newFile.path isEqualToString:filename]) return;
			expect(headToIndex.status).to.equal(headToIndexStatus);
			expect(indexToWorkingDirectory.status).to.equal(indexToWorkingDirectoryStatus);
		}];
	};

	beforeEach(^{
		expect(filename).to.equal([filename precomposedStringWithCanonicalMapping]);
		repo = self.testUnicodeFixtureRepository;
		configuration = [repo configurationWithError:NULL];

		[configuration setBool:false forKey:@"core.precomposeunicode"];
		expect([configuration boolForKey:@"core.precomposeunicode"]).to.beFalsy();

		index = [repo indexWithError:NULL];

		NSString *path = [repo.fileURL.path stringByAppendingPathComponent:filename];
		fileURL = [NSURL fileURLWithPath:path isDirectory:NO];

		NSString *newPath = [repo.fileURL.path stringByAppendingPathComponent:renamedFilename];
		renamedFileURL = [NSURL fileURLWithPath:newPath isDirectory:NO];
	});

	it(@"it preserves decomposed Unicode in index paths with precomposeunicode disabled", ^{
		NSString *decomposedFilename = [filename decomposedStringWithCanonicalMapping];
		GTIndexEntry *entry = [index entryWithName:decomposedFilename error:NULL];
		expect(fileStatusEqualsExpected(entry.path, GTStatusDeltaStatusUnmodified, GTStatusDeltaStatusUnmodified)).to.beTruthy();

		expect([[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:renamedFileURL error:NULL]).to.beTruthy();

		entry = [index entryWithName:decomposedFilename error:NULL];
		expect(fileStatusEqualsExpected(entry.path, GTStatusDeltaStatusUnmodified, GTStatusDeltaStatusDeleted)).to.beTruthy();

		[index removeFile:filename error:NULL];
		[index addFile:renamedFilename error:NULL];
		[index write:NULL];

		entry = [index entryWithName:[renamedFilename decomposedStringWithCanonicalMapping] error:NULL];
		expect(fileStatusEqualsExpected(entry.path, GTStatusDeltaStatusRenamed, GTStatusDeltaStatusUnmodified)).to.beTruthy();
	});

	it(@"it preserves precomposed Unicode in index paths with precomposeunicode enabled", ^{
		GTIndexEntry *fileEntry = [index entryWithName:[filename decomposedStringWithCanonicalMapping] error:NULL];
		expect(fileEntry).toNot.beNil();
		expect(fileStatusEqualsExpected(fileEntry.path, GTStatusDeltaStatusUnmodified, GTStatusDeltaStatusUnmodified)).to.beTruthy();

		[configuration setBool:true forKey:@"core.precomposeunicode"];
		expect([configuration boolForKey:@"core.precomposeunicode"]).to.beTruthy();

		GTIndexEntry *decomposedFileEntry = [index entryWithName:[filename decomposedStringWithCanonicalMapping] error:NULL];
		expect(decomposedFileEntry).toNot.beNil();
		expect(fileStatusEqualsExpected(decomposedFileEntry.path, GTStatusDeltaStatusUnmodified, GTStatusDeltaStatusDeleted)).to.beTruthy();

		expect([[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:renamedFileURL error:NULL]).to.beTruthy();

		GTIndexEntry *precomposedFileEntry = [index entryWithName:filename error:NULL];
		expect(precomposedFileEntry).to.beNil();

		decomposedFileEntry = [index entryWithName:[filename decomposedStringWithCanonicalMapping] error:NULL];
		expect(decomposedFileEntry).toNot.beNil();
		expect(fileStatusEqualsExpected(decomposedFileEntry.path, GTStatusDeltaStatusUnmodified, GTStatusDeltaStatusDeleted)).to.beTruthy();

		[index removeFile:filename error:NULL];
		[index addFile:renamedFilename error:NULL];
		[index write:NULL];

		GTIndexEntry *precomposedRenamedFileEntry = [index entryWithName:renamedFilename error:NULL];
		expect(precomposedRenamedFileEntry).toNot.beNil();
		expect(fileStatusEqualsExpected(precomposedFileEntry.path, GTStatusDeltaStatusRenamed, GTStatusDeltaStatusUntracked)).to.beTruthy();
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
