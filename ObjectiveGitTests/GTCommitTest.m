//
//  GTCommitTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
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

@interface GTCommitTest : SenTestCase {

	GTRepository *repo;
}
@end

@implementation GTCommitTest


- (void)setUp {
	
	NSError *error = nil;
    repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNotNil(repo, [error localizedDescription]);
}

- (void)testCanReadCommitData {
	
	NSString *commitSHA = @"8496071c1b46c854b31185ea97743be6a8774479";
	NSError *error = nil;
	GTObject *obj = [repo lookupObjectBySHA:commitSHA error:&error];
	
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(obj, nil);
	STAssertTrue([obj isKindOfClass:[GTCommit class]], nil);
	STAssertEqualObjects(obj.type, @"commit", nil);
	STAssertEqualObjects(obj.SHA, commitSHA, nil);
	
	GTCommit *commit = (GTCommit *)obj;
	STAssertEqualObjects(commit.message, @"testing\n", nil);
	STAssertEqualObjects(commit.messageSummary, @"testing", nil);
	STAssertEqualObjects(commit.messageDetails, @"", nil);
	STAssertEquals((int)[commit.commitDate timeIntervalSince1970], 1273360386, nil); 
	
	GTSignature *author = commit.author;
	STAssertEqualObjects(author.name, @"Scott Chacon", nil);
	STAssertEqualObjects(author.email, @"schacon@gmail.com", nil);
	STAssertEquals((int)[author.time timeIntervalSince1970], 1273360386, nil);
	
	GTSignature *committer = commit.committer;
	STAssertEqualObjects(committer.name, @"Scott Chacon", nil);
	STAssertEqualObjects(committer.email, @"schacon@gmail.com", nil);
	STAssertEquals((int)[committer.time timeIntervalSince1970], 1273360386, nil);
	
	STAssertEqualObjects(commit.tree.SHA, @"181037049a54a1eb5fab404658a3a250b44335d7", nil);
	STAssertTrue([commit.parents count] == 0, nil);
}

- (void)testCanHaveMultipleParents {
	
	NSString *commitSHA = @"a4a7dce85cf63874e984719f4fdd239f5145052f";
	NSError *error = nil;
	GTObject *obj = [repo lookupObjectBySHA:commitSHA error:&error];
	
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(obj, nil);
	
	GTCommit *commit = (GTCommit *)obj;
	STAssertTrue([commit.parents count] == 2, nil);
}

@end
