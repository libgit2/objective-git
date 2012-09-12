//
//  GTTagTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
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

#import "Contants.h"


@interface GTTagTest : SenTestCase {}
@end

@implementation GTTagTest

- (void)testCanReadTagData {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	GTTag *tag = (GTTag *)[repo lookupObjectBySha:sha error:&error];
	
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(tag, nil);
	STAssertEqualObjects(sha, tag.sha, nil);
	STAssertEqualObjects(@"tag", tag.type, nil);
	STAssertEqualObjects(@"test tag message\n", tag.message, nil);
	STAssertEqualObjects(@"v1.0", tag.name, nil);
	STAssertEqualObjects(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", tag.target.sha, nil);
	STAssertEqualObjects(@"commit", tag.targetType, nil);
	
	GTSignature *c = tag.tagger;
	STAssertEqualObjects(@"Scott Chacon", c.name, nil);
	STAssertEquals(1288114383, (int)[c.time timeIntervalSince1970], nil);
	STAssertEqualObjects(@"schacon@gmail.com", c.email, nil);
}

- (void)testCreateTagWithSameNameFails {
	
	NSError *error = nil;
	NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	GTTag *tag = (GTTag *)[repo lookupObjectBySha:sha error:&error];
	
	[GTTag shaByCreatingTagInRepository:repo name:tag.name target:tag.target tagger:tag.tagger message:@"new message" error:&error];
	STAssertNotNil(error, nil);
}

- (void)testCreateTag {
	NSError *error = nil;
	NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	GTTag *tag = (GTTag *)[repo lookupObjectBySha:sha error:&error];

	NSString *newSha = [GTTag shaByCreatingTagInRepository:repo name:@"a_new_tag" target:tag.target tagger:tag.tagger message:@"my tag\n" error:&error];
	STAssertNotNil(newSha, [error localizedDescription]);
	
	tag = (GTTag *)[repo lookupObjectBySha:newSha error:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(tag, nil);
	STAssertEqualObjects(newSha, tag.sha, nil);
	STAssertEqualObjects(@"tag", tag.type, nil);
	STAssertEqualObjects(@"my tag\n", tag.message, nil);
	STAssertEqualObjects(@"a_new_tag", tag.name, nil);
	STAssertEqualObjects(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", tag.target.sha, nil);
	STAssertEqualObjects(@"commit", tag.targetType, nil);

	rm_loose(self.class, newSha);
	NSFileManager *m = [[NSFileManager alloc] init];
	NSURL *tagPath = [[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] URLByAppendingPathComponent:@"refs/tags/a_new_tag"];
	[m removeItemAtURL:tagPath error:&error];
}

@end
