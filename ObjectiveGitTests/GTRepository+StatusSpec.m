//
//  GTRepository+StatusSpec
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 2013-08-08.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(GTRepositoryStatus)

describe(@"Checking status", ^{
	__block GTRepository *repository = nil;
	__block NSURL *targetFileURL = nil;

	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
	
	beforeEach(^{
		repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_APP_REPO_PATH(self.class)] error:NULL];
		targetFileURL = [repository.fileURL URLByAppendingPathComponent:@"main.m"];
		expect(repository).toNot.beNil();
	});
	
	it(@"should recognise untracked files", ^{
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {\
			if (![indexToWorkingDirectory.newFile.path isEqualToString:@"UntrackedImage.png"]) return;
			expect(indexToWorkingDirectory.status).to.equal(GTStatusDeltaStatusUntracked);
		}];
	});
	
	it(@"should recognise added files", ^{
		//TODO: figure out the best way to stage files for this test.
	});
	
	it(@"should recognise modified files", ^{
		[NSFileManager.defaultManager removeItemAtURL:targetFileURL error:NULL];
		[testData writeToURL:targetFileURL atomically:YES];
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![indexToWorkingDirectory.newFile.path isEqualToString:targetFileURL.lastPathComponent]) return;
			expect(indexToWorkingDirectory.status).to.equal(GTStatusDeltaStatusModified);
		}];
	});
	
	it(@"should recognise deleted files", ^{
		[NSFileManager.defaultManager removeItemAtURL:targetFileURL error:NULL];
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![indexToWorkingDirectory.newFile.path isEqualToString:targetFileURL.lastPathComponent]) return;
			expect(indexToWorkingDirectory.status).to.equal(GTStatusDeltaStatusDeleted);
		}];
	});
	
	it(@"should recognise copied files", ^{
		NSURL *copyLocation = [repository.fileURL URLByAppendingPathComponent:@"main2.m"];
		[NSFileManager.defaultManager copyItemAtURL:targetFileURL toURL:copyLocation error:NULL];
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![indexToWorkingDirectory.newFile.path isEqualToString:copyLocation.lastPathComponent]) return;
			expect(indexToWorkingDirectory.status).to.equal(GTStatusDeltaStatusCopied);
		}];
	});
	
	it(@"should recognise renamed files", ^{
		NSURL *moveLocation = [repository.fileURL URLByAppendingPathComponent:@"main-moved.m"];
		[NSFileManager.defaultManager moveItemAtURL:targetFileURL toURL:moveLocation error:NULL];
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![indexToWorkingDirectory.newFile.path isEqualToString:moveLocation.lastPathComponent]) return;
			expect(indexToWorkingDirectory.status).to.equal(GTStatusDeltaStatusRenamed);
		}];
	});
	
	it(@"should recognise ignored files", ^{ //at least in the default options
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![indexToWorkingDirectory.newFile.path isEqualToString:@".DS_Store"]) return;
			expect(indexToWorkingDirectory.status).to.equal(GTStatusDeltaStatusIgnored);
		}];
	});
	
	it(@"should skip ignored files if asked", ^{
		NSDictionary *options = @{ GTRepositoryStatusOptionsFlagsKey: @(0) };
		[repository enumerateFileStatusWithOptions:options usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			expect(indexToWorkingDirectory.status).toNot.equal(GTStatusDeltaStatusIgnored);
		}];
	});
});

SpecEnd
