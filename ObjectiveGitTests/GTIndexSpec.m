//
//  GTIndexSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 5/10/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

@import ObjectiveGit;
@import Nimble;
@import Quick;

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTIndexSpec)

__block GTRepository *repository;
__block GTIndex *index;

beforeEach(^{
	repository = self.testAppFixtureRepository;

	index = [repository indexWithError:NULL];
	expect(index).notTo(beNil());

	BOOL success = [index refresh:NULL];
	expect(@(success)).to(beTruthy());
});

it(@"should count the entries", ^{
	expect(@(index.entryCount)).to(equal(@24));
});

it(@"should clear all entries", ^{
	[index clear:NULL];
	expect(@(index.entryCount)).to(equal(@0));
});

it(@"should read entry properties", ^{
	GTIndexEntry *entry = [index entryAtIndex:0];
	expect(entry).notTo(beNil());
	expect(entry.path).to(equal(@".gitignore"));
	expect(@(entry.staged)).to(beFalsy());
});

it(@"should write to the repository and return a tree", ^{
	GTTree *tree = [index writeTree:NULL];
	expect(tree).notTo(beNil());
	expect(@(tree.entryCount)).to(equal(@23));
	expect(tree.repository).to(equal(repository));
});

it(@"should write to a specific repository and return a tree", ^{
	GTRepository *repository = self.bareFixtureRepository;
	NSArray *branches = [repository branches:NULL];
	GTCommit *masterCommit = [branches[0] targetCommitWithError:NULL];
	GTCommit *packedCommit = [branches[1] targetCommitWithError:NULL];

	expect(masterCommit).notTo(beNil());
	expect(packedCommit).notTo(beNil());

	GTIndex *index = [masterCommit.tree merge:packedCommit.tree ancestor:NULL error:NULL];
	GTTree *mergedTree = [index writeTreeToRepository:repository error:NULL];

	expect(index).notTo(beNil());
	expect(mergedTree).notTo(beNil());
	expect(@(mergedTree.entryCount)).to(equal(@5));
	expect(mergedTree.repository).to(equal(repository));
});

it(@"should create an index in memory", ^{
	GTIndex *memoryIndex = [GTIndex inMemoryIndexWithRepository:repository error:NULL];
	expect(memoryIndex).notTo(beNil());
	expect(memoryIndex.fileURL).to(beNil());
});

it(@"should add the contents of a tree", ^{
	GTCommit *headCommit = [repository lookUpObjectByRevParse:@"HEAD" error:NULL];
	expect(headCommit).notTo(beNil());

	GTTree *headTree = headCommit.tree;
	expect(@(headTree.entryCount)).to(beGreaterThan(@0));

	GTIndex *memoryIndex = [GTIndex inMemoryIndexWithRepository:index.repository error:NULL];
	expect(memoryIndex).notTo(beNil());
	expect(@(memoryIndex.entryCount)).to(equal(@0));

	BOOL success = [memoryIndex addContentsOfTree:headTree error:NULL];
	expect(@(success)).to(beTruthy());

	[headTree enumerateEntriesWithOptions:GTTreeEnumerationOptionPre error:NULL block:^(GTTreeEntry *treeEntry, NSString *root, BOOL *stop) {
		if (treeEntry.type == GTObjectTypeBlob) {
			NSString *path = [root stringByAppendingString:treeEntry.name];

			GTIndexEntry *indexEntry = [memoryIndex entryWithPath:path];
			expect(indexEntry).notTo(beNil());
		}

		return YES;
	}];
});

describe(@"conflict enumeration", ^{
	it(@"should correctly find no conflicts", ^{
		expect(@(index.hasConflicts)).to(beFalsy());
	});

	it(@"should immediately return YES when enumerating no conflicts", ^{
		__block BOOL blockRan = NO;
		BOOL enumerationResult = [index enumerateConflictedFilesWithError:NULL usingBlock:^(GTIndexEntry *ancestor, GTIndexEntry *ours, GTIndexEntry *theirs, BOOL *stop) {
			blockRan = YES;
		}];
		expect(@(enumerationResult)).to(beTruthy());
		expect(@(blockRan)).to(beFalsy());
	});

	it(@"should correctly report conflicts", ^{
		index = [self.conflictedFixtureRepository indexWithError:NULL];
		expect(index).notTo(beNil());
		expect(@(index.hasConflicts)).to(beTruthy());
	});

	it(@"should enumerate conflicts successfully", ^{
		index = [self.conflictedFixtureRepository indexWithError:NULL];
		expect(index).notTo(beNil());

		NSError *err = NULL;
		__block NSUInteger count = 0;
		NSArray *expectedPaths = @[ @"TestAppDelegate.h", @"main.m" ];
		BOOL enumerationResult = [index enumerateConflictedFilesWithError:&err usingBlock:^(GTIndexEntry *ancestor, GTIndexEntry *ours, GTIndexEntry *theirs, BOOL *stop) {
			expect(ours.path).to(equal(expectedPaths[count]));
			count ++;
		}];

		expect(@(enumerationResult)).to(beTruthy());
		expect(err).to(beNil());
		expect(@(count)).to(equal(@2));
	});
});

describe(@"updating pathspecs", ^{
	NSString *fileName = @"REAME_";
	beforeEach(^{
		index = [self.testAppFixtureRepository indexWithError:NULL];
		NSString *filePath = [self.testAppFixtureRepository.fileURL.path stringByAppendingPathComponent:fileName];
		[@"The wild west..." writeToFile:filePath atomically:NO encoding:NSUTF8StringEncoding error:NULL];

		expect(index).notTo(beNil());
		expect(@([index.repository statusForFile:fileName success:NULL error:NULL])).to(equal(@(GTFileStatusModifiedInWorktree)));
	});

	it(@"should update the Index", ^{
		BOOL success = [index updatePathspecs:@[ fileName ] error:NULL passingTest:^(NSString *matchedPathspec, NSString *path, BOOL *stop) {
			expect(matchedPathspec).to(equal(fileName));
			expect(path).to(equal(fileName));
			return YES;
		}];

		expect(@(success)).to(beTruthy());
		expect(@([index.repository statusForFile:fileName success:NULL error:NULL])).to(equal(@(GTFileStatusModifiedInIndex)));
	});

	it(@"should skip a specific file", ^{
		BOOL success = [index updatePathspecs:NULL error:NULL passingTest:^(NSString *matchedPathspec, NSString *path, BOOL *stop) {
			if ([path.lastPathComponent isEqualToString:fileName]) {
				return NO;
			} else {
				return YES;
			}
		}];

		expect(@(success)).to(beTruthy());
		expect(@([index.repository statusForFile:fileName success:NULL error:NULL])).to(equal(@(GTFileStatusModifiedInWorktree)));
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

		expect(@(success)).to(beTruthy());
		expect(@([index.repository statusForFile:fileName success:NULL error:NULL])).to(equal(@(GTFileStatusModifiedInIndex)));
		expect(@([index.repository statusForFile:otherFileName success:NULL error:NULL])).to(equal(@(GTFileStatusModifiedInWorktree)));
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

	BOOL (^fileStatusEqualsExpected)(NSString *filename, GTDeltaType headToIndexStatus, GTDeltaType indexToWorkingDirectoryStatus) = ^(NSString *filename, GTDeltaType headToIndexStatus, GTDeltaType indexToWorkingDirectoryStatus) {
		return [index.repository enumerateFileStatusWithOptions:renamedOptions error:NULL usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![headToIndex.newFile.path isEqualToString:filename]) return;
			expect(@(headToIndex.status)).to(equal(@(headToIndexStatus)));
			expect(@(indexToWorkingDirectory.status)).to(equal(@(indexToWorkingDirectoryStatus)));
		}];
	};

	beforeEach(^{
		expect(filename).to(equal([filename precomposedStringWithCanonicalMapping]));
		repo = self.testUnicodeFixtureRepository;
		configuration = [repo configurationWithError:NULL];

		[configuration setBool:false forKey:@"core.precomposeunicode"];
		expect(@([configuration boolForKey:@"core.precomposeunicode"])).to(beFalsy());

		index = [repo indexWithError:NULL];

		NSString *path = [repo.fileURL.path stringByAppendingPathComponent:filename];
		fileURL = [NSURL fileURLWithPath:path isDirectory:NO];

		NSString *newPath = [repo.fileURL.path stringByAppendingPathComponent:renamedFilename];
		renamedFileURL = [NSURL fileURLWithPath:newPath isDirectory:NO];
	});

	it(@"should add all files from the current file system to the index", ^{
		NSData *currentFileContent = [[NSFileManager defaultManager] contentsAtPath:fileURL.path];
		expect(currentFileContent).notTo(beNil());
		NSString *currentFileString = [[NSString alloc] initWithData:currentFileContent encoding:NSUTF8StringEncoding];
		currentFileString = [currentFileString stringByAppendingString:@"I would like to append this to the file"];
		currentFileContent = [currentFileString dataUsingEncoding:NSUTF8StringEncoding];
		expect(@([[NSFileManager defaultManager] createFileAtPath:fileURL.path contents:currentFileContent attributes:nil])).to(beTruthy());

		NSString *newFileContent = @"This is a new file \n1 2 3";
		NSData *newFileData = [newFileContent dataUsingEncoding:NSUTF8StringEncoding];
		expect(newFileData).notTo(beNil());
		expect(@([[NSFileManager defaultManager] createFileAtPath:renamedFileURL.path contents:newFileData attributes:nil])).to(beTruthy());

		GTIndexEntry *entry = [index entryWithPath:[filename decomposedStringWithCanonicalMapping]];
		expect(@(fileStatusEqualsExpected(entry.path, GTDeltaTypeUnmodified, GTDeltaTypeModified))).to(beTruthy());
		entry = [index entryWithPath:[renamedFilename decomposedStringWithCanonicalMapping]];
		expect(@(fileStatusEqualsExpected(entry.path, GTDeltaTypeUnmodified, GTDeltaTypeUntracked))).to(beTruthy());

		expect(@([index addAll:NULL])).to(beTruthy());
		expect(@([index write:NULL])).to(beTruthy());

		entry = [index entryWithPath:[filename decomposedStringWithCanonicalMapping]];
		expect(@(fileStatusEqualsExpected(entry.path, GTDeltaTypeModified, GTDeltaTypeUnmodified))).to(beTruthy());
		entry = [index entryWithPath:[renamedFilename decomposedStringWithCanonicalMapping]];
		expect(@(fileStatusEqualsExpected(entry.path, GTDeltaTypeAdded, GTDeltaTypeUnmodified))).to(beTruthy());
	});

	it(@"it preserves decomposed Unicode in index paths with precomposeunicode disabled", ^{
		NSString *decomposedFilename = [filename decomposedStringWithCanonicalMapping];
		GTIndexEntry *entry = [index entryWithPath:decomposedFilename error:NULL];
		expect(@(fileStatusEqualsExpected(entry.path, GTDeltaTypeUnmodified, GTDeltaTypeUnmodified))).to(beTruthy());

		expect(@([[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:renamedFileURL error:NULL])).to(beTruthy());

		entry = [index entryWithPath:decomposedFilename error:NULL];
		expect(@(fileStatusEqualsExpected(entry.path, GTDeltaTypeUnmodified, GTDeltaTypeDeleted))).to(beTruthy());

		[index removeFile:filename error:NULL];
		[index addFile:renamedFilename error:NULL];
		[index write:NULL];

		entry = [index entryWithPath:[renamedFilename decomposedStringWithCanonicalMapping] error:NULL];
		expect(@(fileStatusEqualsExpected(entry.path, GTDeltaTypeRenamed, GTDeltaTypeUnmodified))).to(beTruthy());
	});

	it(@"it preserves precomposed Unicode in index paths with precomposeunicode enabled", ^{
		GTIndexEntry *fileEntry = [index entryWithPath:[filename decomposedStringWithCanonicalMapping] error:NULL];
		expect(fileEntry).notTo(beNil());
		expect(@(fileStatusEqualsExpected(fileEntry.path, GTDeltaTypeUnmodified, GTDeltaTypeUnmodified))).to(beTruthy());

		[configuration setBool:true forKey:@"core.precomposeunicode"];
		expect(@([configuration boolForKey:@"core.precomposeunicode"])).to(beTruthy());

		GTIndexEntry *decomposedFileEntry = [index entryWithPath:[filename decomposedStringWithCanonicalMapping] error:NULL];
		expect(decomposedFileEntry).notTo(beNil());
		expect(@(fileStatusEqualsExpected(decomposedFileEntry.path, GTDeltaTypeUnmodified, GTDeltaTypeDeleted))).to(beTruthy());

		expect(@([[NSFileManager defaultManager] moveItemAtURL:fileURL toURL:renamedFileURL error:NULL])).to(beTruthy());

		GTIndexEntry *precomposedFileEntry = [index entryWithPath:filename error:NULL];
		expect(precomposedFileEntry).to(beNil());

		decomposedFileEntry = [index entryWithPath:[filename decomposedStringWithCanonicalMapping] error:NULL];
		expect(decomposedFileEntry).notTo(beNil());
		expect(@(fileStatusEqualsExpected(decomposedFileEntry.path, GTDeltaTypeUnmodified, GTDeltaTypeDeleted))).to(beTruthy());

		[index removeFile:filename error:NULL];
		[index addFile:renamedFilename error:NULL];
		[index write:NULL];

		GTIndexEntry *precomposedRenamedFileEntry = [index entryWithPath:renamedFilename error:NULL];
		expect(precomposedRenamedFileEntry).notTo(beNil());
		expect(@(fileStatusEqualsExpected(precomposedFileEntry.path, GTDeltaTypeRenamed, GTDeltaTypeUntracked))).to(beTruthy());
	});
});

describe(@"adding data", ^{
	__block GTRepository *repo;
	__block GTIndex *index;
	__block NSError *error;
	
	beforeEach(^{
		error = nil;
		repo = self.testUnicodeFixtureRepository;
		// Not sure why but it doesn't work with an in memory index
		// index = [GTIndex inMemoryIndexWithRepository:repo error:&error];
		index = [repo indexWithError:&error];
		expect(error).to(beNil());
	});
	
	it(@"should store data at given path", ^{
		NSData *data = [NSData dataWithBytes:"foo" length:4];
		[index addData:data withPath:@"bar/foo" error:&error];
		expect(error).to(beNil());
		
		GTIndexEntry *entry = [index entryWithPath:@"bar/foo" error:&error];
		expect(entry).notTo(beNil());
		expect(error).to(beNil());
	});
});

describe(@"-resultOfMergingAncestorEntry:ourEntry:theirEntry:options:error:", ^{
	it(@"should produce a nice merge conflict description", ^{
		NSURL *mainURL = [repository.fileURL URLByAppendingPathComponent:@"main.m"];
		NSData *mainData = [[NSFileManager defaultManager] contentsAtPath:mainURL.path];
		expect(mainData).notTo(beNil());

		NSString *mainString = [[NSString alloc] initWithData:mainData encoding:NSUTF8StringEncoding];
		NSData *masterData = [[mainString stringByReplacingOccurrencesOfString:@"return" withString:@"//The meaning of life is 41\n    return"] dataUsingEncoding:NSUTF8StringEncoding];
		NSData *otherData = [[mainString stringByReplacingOccurrencesOfString:@"return" withString:@"//The meaning of life is 42\n    return"] dataUsingEncoding:NSUTF8StringEncoding];

		expect(@([[NSFileManager defaultManager] createFileAtPath:mainURL.path contents:masterData attributes:nil])).to(beTruthy());

		GTIndex *index = [repository indexWithError:NULL];
		expect(@([index addFile:mainURL.lastPathComponent error:NULL])).to(beTruthy());
		GTReference *head = [repository headReferenceWithError:NULL];
		GTCommit *parent = [repository lookUpObjectByOID:head.targetOID objectType:GTObjectTypeCommit error:NULL];
		expect(parent).toNot(beNil());
		GTTree *masterTree = [index writeTree:NULL];
		expect(masterTree).toNot(beNil());

		GTBranch *otherBranch = [repository lookUpBranchWithName:@"other-branch" type:GTBranchTypeLocal success:NULL error:NULL];
		expect(otherBranch).toNot(beNil());
		expect(@([repository checkoutReference:otherBranch.reference options:nil error:NULL])).to(beTruthy());

		expect(@([[NSFileManager defaultManager] createFileAtPath:mainURL.path contents:otherData attributes:nil])).to(beTruthy());

		index = [repository indexWithError:NULL];
		expect(@([index addFile:mainURL.lastPathComponent error:NULL])).to(beTruthy());
		GTTree *otherTree = [index writeTree:NULL];
		expect(otherTree).toNot(beNil());

		GTIndex *conflictIndex = [otherTree merge:masterTree ancestor:parent.tree error:NULL];
		expect(@([conflictIndex hasConflicts])).to(beTruthy());

		[conflictIndex enumerateConflictedFilesWithError:NULL usingBlock:^(GTIndexEntry * _Nonnull ancestor, GTIndexEntry * _Nonnull ours, GTIndexEntry * _Nonnull theirs, BOOL * _Nonnull stop) {

			GTMergeResult *result = [conflictIndex resultOfMergingAncestorEntry:ancestor ourEntry:ours theirEntry:theirs options:nil error:NULL];
			expect(result).notTo(beNil());

			NSString *conflictString = [[NSString alloc] initWithData:result.data encoding:NSUTF8StringEncoding];
			NSString *expectedString = @"//\n"
			"//  main.m\n"
			"//  Test\n"
			"//\n"
			"//  Created by Joe Ricioppo on 9/28/10.\n"
			"//  Copyright 2010 __MyCompanyName__. All rights reserved.\n"
			"//\n"
			"\n"
			"#import <Cocoa/Cocoa.h>\n"
			"\n"
			"int main(int argc, char *argv[])\n"
			"{\n"
			"<<<<<<< main.m\n"
			"    //The meaning of life is 42\n"
			"=======\n"
			"    //The meaning of life is 41\n"
			">>>>>>> main.m\n"
			"    return NSApplicationMain(argc,  (const char **) argv);\n"
			"}\n"
			"123456789\n"
			"123456789\n"
			"123456789\n"
			"123456789!blah!\n";

			expect(conflictString).to(equal(expectedString));
		}];
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
