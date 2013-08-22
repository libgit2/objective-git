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
	
	void(^updateIndexForSubpathAndExpectStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus expectedIndexStatus) {
		NSError *err = nil;
		GTIndex *index = [repository indexWithError:&err];
		expect(err).to.beNil();
		expect(index).toNot.beNil();
		
		expect(git_index_update_all(index.git_index, NULL, NULL, NULL)).to.equal(GIT_OK);
		
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![headToIndex.newFile.path isEqualToString:subpath]) return;
			expect(headToIndex.status).to.equal(expectedIndexStatus);
		}];
	};
	
	void(^expectSubpathToHaveWorkDirStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus expectedWorkDirStatus) {
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {\
			if (![indexToWorkingDirectory.newFile.path isEqualToString:subpath]) return;
			expect(indexToWorkingDirectory.status).to.equal(expectedWorkDirStatus);
		}];
	};
	
	void(^expectSubpathToHaveMatchingStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus status) {
		expectSubpathToHaveWorkDirStatus(subpath, status);
		updateIndexForSubpathAndExpectStatus(subpath, status);
	};
	
	it(@"should recognise untracked files", ^{
		expectSubpathToHaveWorkDirStatus(@"UntrackedImage.png", GTStatusDeltaStatusUntracked);
	});
	
	it(@"should recognise added files", ^{
		updateIndexForSubpathAndExpectStatus(@"UntrackedImage.png", GTStatusDeltaStatusAdded);
	});
	
	it(@"should recognise modified files", ^{
		[NSFileManager.defaultManager removeItemAtURL:targetFileURL error:NULL];
		[testData writeToURL:targetFileURL atomically:YES];
		expectSubpathToHaveMatchingStatus(targetFileURL.lastPathComponent, GTStatusDeltaStatusModified);
	});
	
	it(@"should recognise deleted files", ^{
		[NSFileManager.defaultManager removeItemAtURL:targetFileURL error:NULL];
		expectSubpathToHaveMatchingStatus(targetFileURL.lastPathComponent, GTStatusDeltaStatusDeleted);
	});
	
	it(@"should recognise copied files", ^{
		NSURL *copyLocation = [repository.fileURL URLByAppendingPathComponent:@"main2.m"];
		[NSFileManager.defaultManager copyItemAtURL:targetFileURL toURL:copyLocation error:NULL];
		expectSubpathToHaveMatchingStatus(copyLocation.lastPathComponent, GTStatusDeltaStatusCopied);
	});
	
	it(@"should recognise renamed files", ^{
		NSURL *moveLocation = [repository.fileURL URLByAppendingPathComponent:@"main-moved.m"];
		[NSFileManager.defaultManager moveItemAtURL:targetFileURL toURL:moveLocation error:NULL];
		expectSubpathToHaveMatchingStatus(moveLocation.lastPathComponent, GTStatusDeltaStatusRenamed);
	});
	
	it(@"should recognise ignored files", ^{ //at least in the default options
		expectSubpathToHaveWorkDirStatus(@".DS_Store", GTStatusDeltaStatusIgnored);
	});
	
	it(@"should skip ignored files if asked", ^{
		NSDictionary *options = @{ GTRepositoryStatusOptionsFlagsKey: @(0) };
		[repository enumerateFileStatusWithOptions:options usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			expect(indexToWorkingDirectory.status).toNot.equal(GTStatusDeltaStatusIgnored);
		}];
	});
});

SpecEnd
