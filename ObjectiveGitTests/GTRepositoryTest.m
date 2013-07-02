//
//  GTRepositoryTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/21/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

@interface GTRepositoryTest : SenTestCase {

	GTRepository *repo;
	NSString *testContent;
	GTObjectType testContentType;
}
@end


@implementation GTRepositoryTest
 
- (void)setUp {
	
	NSError *error = nil;
    repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	testContent = @"my test data\n";
	testContentType = GTObjectTypeBlob;
}

- (void)removeDirectoryAtURL:(NSURL *)url {
	NSFileManager *fm = [[NSFileManager alloc] init];
	NSError *error = nil;
	
	if([fm fileExistsAtPath:url.path]) {
		STAssertTrue([fm removeItemAtPath:url.path error:&error], [error localizedDescription]);
	}
}

- (void)testCreateRepositoryInDirectory {
	
	NSError *error = nil;
	NSURL *newRepoURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"unit_test"]];

	[self removeDirectoryAtURL:newRepoURL];
	
    STAssertTrue([GTRepository initializeEmptyRepositoryAtURL:newRepoURL error:&error], nil);
	GTRepository *newRepo = [GTRepository repositoryWithURL:newRepoURL error:&error];
	
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(newRepo, nil);
	STAssertNotNil(newRepo.fileURL, nil);
}

- (void)testFailsToOpenNonExistentRepo {
	
	NSError *error = nil;
	GTRepository *badRepo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:@"fake/1235"] error:&error];
	
	STAssertNil(badRepo, nil);
	STAssertNotNil(error, nil);
	NSLog(@"error = %@", [error localizedDescription]);
}

- (void)testCanHashData {
	
	NSError *error = nil;
	NSString *sha = [GTRepository hash:testContent objectType:testContentType error:&error];
	STAssertEqualObjects(sha, @"76b1b55ab653581d6f2c7230d34098e837197674", nil);
}

- (void)testLookupHead {
	
	NSError *error = nil;
	GTReference *head = [repo headReferenceWithError:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertEqualObjects(head.target, @"36060c58702ed4c2a40832c51758d5344201d89a", nil);
	STAssertEqualObjects(head.type, @"commit", nil);
}

- (void)testIsEmpty {
	STAssertFalse([repo isEmpty], nil);
}

- (void)testCanReset {
    NSError *err = nil;
    GTRepository *aRepo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&err];
    STAssertNotNil(aRepo, @"Repository failed to initialise");
    GTReference *originalHead = [aRepo headReferenceWithError:NULL];
    NSString *resetTargetSha = @"8496071c1b46c854b31185ea97743be6a8774479";

	GTCommit *commit = (GTCommit *)[aRepo lookupObjectBySha:resetTargetSha error:NULL];
    
    BOOL success = [aRepo resetToCommit:commit withResetType:GTRepositoryResetTypeSoft error:&err];
    STAssertTrue(success, @"Failed to reset, error given: %@", err);
    GTReference *head = [aRepo headReferenceWithError:&err];
    STAssertEqualObjects(head.target, resetTargetSha, @"Reset failed to move head to given commit");
    
    GTCommit *originalHeadCommit = (GTCommit *)[aRepo lookupObjectBySha:originalHead.target error:NULL];
    [aRepo resetToCommit:originalHeadCommit withResetType:GTRepositoryResetTypeSoft error:NULL];
    head = [aRepo headReferenceWithError:&err];
    STAssertEqualObjects(head.target, originalHead.target, @"Reset failed to move head back to the original position");
}

- (void)expectSHA:(NSString*)sha forRefspec:(NSString*)refspec {
	NSError *err = nil;
	GTObject *obj = [repo lookupObjectByRefspec:refspec error:&err];

	if (sha != nil) {
		STAssertEquals((NSInteger)GIT_OK, err.code, @"git_revparse_single didn't return 0: %d", err.code);
		STAssertNotNil(obj, @"Couldn't find object for %@", refspec);
		STAssertEqualObjects(sha, obj.sha, @"Revparse '%@': expected %@, got %@", refspec, sha, obj.sha);
	} else {
		STAssertTrue(err.code != (NSInteger)GIT_OK, @"Expected error code, got 0");
		STAssertNil(obj, @"Got object when expected none for %@", refspec);
	}
}

- (void)testCanRevparse {
	[self expectSHA:@"36060c58702ed4c2a40832c51758d5344201d89a" forRefspec:@"master"];
	[self expectSHA:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" forRefspec:@"master~"];
	[self expectSHA:@"8496071c1b46c854b31185ea97743be6a8774479" forRefspec:@"master@{2}"];
	[self expectSHA:nil forRefspec:@"master^2"];
	[self expectSHA:nil forRefspec:@""];
	[self expectSHA:@"0c37a5391bbff43c37f0d0371823a5509eed5b1d" forRefspec:@"v1.0"];

	GTObject *obj = [repo lookupObjectByRefspec:@"master" error:nil];
	STAssertNotNil(obj, @"Call with nil error should still work");
}


- (void)testCanClone {
	__block BOOL transferProgressCalled = NO;
	__block BOOL checkoutProgressCalled = NO;
	void (^transferProgressBlock)(const git_transfer_progress *) = ^(const git_transfer_progress *progress) {
		transferProgressCalled = YES;
	};
	void (^checkoutProgressBlock)(NSString *, NSUInteger, NSUInteger) = ^(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps) {
		checkoutProgressCalled = YES;
	};
	NSURL *originURL = [NSURL fileURLWithPath:TEST_REPO_PATH(self.class)]; //[NSURL URLWithString: @"https://github.com/libgit2/TestGitRepository"];
	NSURL *workdirURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"unit_test"]];
	NSError *err;

	[self removeDirectoryAtURL:workdirURL];

	repo = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL barely:NO withCheckout:YES error:&err transferProgressBlock:transferProgressBlock checkoutProgressBlock:checkoutProgressBlock];

	STAssertNotNil(repo, err.localizedDescription);
	STAssertFalse([repo isBare], @"Standard repo should not be bare");
	STAssertTrue(transferProgressCalled, @"Transfer progress handler never called");
	STAssertTrue(checkoutProgressCalled, @"checkout progress handler never called");

	GTReference *head = [repo headReferenceWithError:&err];
	STAssertNotNil(head, err.localizedDescription);
	STAssertEqualObjects(head.target, @"36060c58702ed4c2a40832c51758d5344201d89a", nil);
	STAssertEqualObjects(head.type, @"commit", nil);
}

- (void)testCanCloneBarely {
	__block BOOL transferProgressCalled = NO;
	__block BOOL checkoutProgressCalled = NO;
	void (^transferProgressBlock)(const git_transfer_progress *) = ^(const git_transfer_progress *progress) {
		transferProgressCalled = YES;
	};
	void (^checkoutProgressBlock)(NSString *, NSUInteger, NSUInteger) = ^(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps) {
		checkoutProgressCalled = YES;
	};
	NSURL *originURL = [NSURL fileURLWithPath:TEST_REPO_PATH(self.class)]; //[NSURL URLWithString: @"https://github.com/libgit2/TestGitRepository"];
	NSURL *workdirURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"unit_test"]];
	NSError *err;

	[self removeDirectoryAtURL:workdirURL];

	repo = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL barely:YES withCheckout:YES error:&err transferProgressBlock:transferProgressBlock checkoutProgressBlock:checkoutProgressBlock];

	STAssertNotNil(repo, err.localizedDescription);
	STAssertTrue([repo isBare], @"Bare repo should be bare");
	STAssertTrue(transferProgressCalled, @"Transfer progress handler never called");
	STAssertFalse(checkoutProgressCalled, @"Checkout progress handler was called for bare repo");

	GTReference *head = [repo headReferenceWithError:&err];
	STAssertNotNil(head, err.localizedDescription);
	STAssertEqualObjects(head.target, @"36060c58702ed4c2a40832c51758d5344201d89a", nil);
	STAssertEqualObjects(head.type, @"commit", nil);
}

//- (void) testCanGetRemotes {
//    NSArray* remotesArray = [repo remoteNames];
//    
//    STAssertTrue( [remotesArray containsObject: @"github"], @"remotes name did not contain expected remote" );
//    STAssertTrue( [repo hasRemoteNamed: @"github"], @"remotes name was not found by query function" );
//    
//}

// This messes other tests up b/c it writes a new HEAD, but doesn't set it back again
/*
- (void)testLookupHeadThenCommitAndThenLookupHeadAgain {
	
	NSError *error = nil;
	GTReference *head = [repo headAndReturnError:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertEqualObjects(head.target, @"36060c58702ed4c2a40832c51758d5344201d89a", nil);
	STAssertEqualObjects(head.type, @"commit", nil);
	
	NSString *tsha = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";
	GTObject *aObj = [repo lookupBySha:tsha error:&error];

	STAssertNotNil(aObj, [error localizedDescription]);
	STAssertTrue([aObj isKindOfClass:[GTTree class]], nil);
	GTTree *tree = (GTTree *)aObj;
	GTSignature *person = [[[GTSignature alloc] 
							initWithName:@"Tim" 
							email:@"tclem@github.com" 
							time:[NSDate date]] autorelease];
	GTCommit *commit = [GTCommit commitInRepo:repo updateRefNamed:@"HEAD" author:person committer:person message:@"new message" tree:tree parents:nil error:&error];
	STAssertNotNil(commit, [error localizedDescription]);
	NSLog(@"wrote sha %@", commit.sha);
	
	head = [repo headAndReturnError:&error];
	STAssertNotNil(head, [error localizedDescription]);
	
	STAssertEqualObjects(head.target, commit.sha, nil);
	
	rm_loose(commit.sha);
}
*/
@end
