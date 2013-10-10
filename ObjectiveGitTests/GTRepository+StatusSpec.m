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
	__block NSError *err;

	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
	
	beforeEach(^{
		repository = self.testAppFixtureRepository;
		targetFileURL = [repository.fileURL URLByAppendingPathComponent:@"main.m"];
		expect(repository).toNot.beNil();
	});
	
	void (^updateIndexForSubpathAndExpectStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus expectedIndexStatus) {
		__block NSError *err = nil;
		GTIndex *index = [repository indexWithError:&err];
		expect(err).to.beNil();
		expect(index).toNot.beNil();
		
		expect(git_index_update_all(index.git_index, NULL, NULL, NULL)).to.equal(GIT_OK);
		
		NSDictionary *renamedOptions = @{ GTRepositoryStatusOptionsFlagsKey: @(GTRepositoryStatusFlagsIncludeIgnored | GTRepositoryStatusFlagsIncludeUntracked | GTRepositoryStatusFlagsRecurseUntrackedDirectories | GTRepositoryStatusFlagsRenamesHeadToIndex) };
		expect([repository enumerateFileStatusWithOptions:renamedOptions error:&err usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![headToIndex.newFile.path isEqualToString:subpath]) return;
			expect(headToIndex.status).to.equal(expectedIndexStatus);
		}]).to.beTruthy();
		expect(err).to.beNil();
	};
	
	void (^expectSubpathToHaveWorkDirStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus expectedWorkDirStatus) {
		__block NSError *err = nil;
		NSDictionary *renamedOptions = @{ GTRepositoryStatusOptionsFlagsKey: @(GTRepositoryStatusFlagsIncludeIgnored | GTRepositoryStatusFlagsIncludeUntracked | GTRepositoryStatusFlagsRecurseUntrackedDirectories | GTRepositoryStatusFlagsRenamesIndexToWorkingDirectory) };
		expect([repository enumerateFileStatusWithOptions:renamedOptions error:&err usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if (![indexToWorkingDirectory.newFile.path isEqualToString:subpath]) return;
			expect(indexToWorkingDirectory.status).to.equal(expectedWorkDirStatus);
		}]).to.beTruthy();
		expect(err).to.beNil();
	};
	
	void (^expectSubpathToHaveMatchingStatus)(NSString *, GTStatusDeltaStatus) = ^(NSString *subpath, GTStatusDeltaStatus status) {
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
		expect([NSFileManager.defaultManager removeItemAtURL:targetFileURL error:&err]).to.beTruthy();
		expect(err).to.beNil();
		expect([testData writeToURL:targetFileURL atomically:YES]).to.beTruthy();
		expectSubpathToHaveMatchingStatus(targetFileURL.lastPathComponent, GTStatusDeltaStatusModified);
	});
		
	it(@"should recognise copied files", ^{
		NSURL *copyLocation = [repository.fileURL URLByAppendingPathComponent:@"main2.m"];
		expect([NSFileManager.defaultManager copyItemAtURL:targetFileURL toURL:copyLocation error:&err]).to.beTruthy();
		expect(err).to.beNil();
		updateIndexForSubpathAndExpectStatus(copyLocation.lastPathComponent, GTStatusDeltaStatusCopied);
	});
	
	it(@"should recognise deleted files", ^{
		expect([NSFileManager.defaultManager removeItemAtURL:targetFileURL error:&err]).to.beTruthy();
		expect(err).to.beNil();
		expectSubpathToHaveMatchingStatus(targetFileURL.lastPathComponent, GTStatusDeltaStatusDeleted);
	});
	
	it(@"should recognise renamed files", ^{
		NSURL *moveLocation = [repository.fileURL URLByAppendingPathComponent:@"main-moved.m"];
		expect([NSFileManager.defaultManager moveItemAtURL:targetFileURL toURL:moveLocation error:&err]).to.beTruthy();
		expect(err).to.beNil();
		expectSubpathToHaveWorkDirStatus(moveLocation.lastPathComponent, GTStatusDeltaStatusRenamed);
	});
	
	it(@"should recognise ignored files", ^{ //at least in the default options
		expectSubpathToHaveWorkDirStatus(@".DS_Store", GTStatusDeltaStatusIgnored);
	});
	
	it(@"should skip ignored files if asked", ^{
		__block NSError *err = nil;
		NSDictionary *options = @{ GTRepositoryStatusOptionsFlagsKey: @(0) };
		BOOL enumerationSuccessful = [repository enumerateFileStatusWithOptions:options error:&err usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			expect(indexToWorkingDirectory.status).toNot.equal(GTStatusDeltaStatusIgnored);
		}];
		expect(enumerationSuccessful).to.beTruthy();
		expect(err).to.beNil();
	});
});

SpecEnd
