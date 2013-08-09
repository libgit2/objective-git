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
	beforeEach(^{
		repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_APP_REPO_PATH(self.class)] error:NULL];
		expect(repository).toNot.beNil();
	});
	
	it(@"should recognise untracked files", ^{
		[repository enumerateFileStatusWithOptions:nil usingBlock:^(GTStatusDelta *headToIndex, GTStatusDelta *indexToWorkingDirectory, BOOL *stop) {
			if ([indexToWorkingDirectory.newFile.path isEqualToString:@"UntrackedImage.png"]) {
				expect(indexToWorkingDirectory.status).to.equal(GTStatusDeltaStatusUntracked);
			}
		}];
	});
	
	it(@"should recognise added files", ^{
		
	});
});

SpecEnd
