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
	NSData *testData = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
	NSURL *targetFileURL = [repository.fileURL URLByAppendingPathComponent:@"main.m"];
	
	beforeEach(^{
		repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_APP_REPO_PATH(self.class)] error:NULL];
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
});

SpecEnd
