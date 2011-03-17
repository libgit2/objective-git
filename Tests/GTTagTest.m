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


@interface GTTagTest : GHTestCase {}
@end

@implementation GTTagTest

- (void)testCanReadTagData {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
	NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	GTTag *tag = (GTTag *)[repo lookupBySha:sha error:&error];
	
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotNil(tag, nil);
	GHAssertEqualStrings(sha, tag.sha, nil);
	GHAssertEqualStrings(@"tag", tag.type, nil);
	GHAssertEqualStrings(@"test tag message\n", tag.message, nil);
	GHAssertEqualStrings(@"v1.0", tag.name, nil);
	GHAssertEqualStrings(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", tag.target.sha, nil);
	GHAssertEqualStrings(@"commit", tag.targetType, nil);
	
	GTSignature *c = tag.tagger;
	GHAssertEqualStrings(@"Scott Chacon", c.name, nil);
	GHAssertEquals(1288114383, (int)[c.time timeIntervalSince1970], nil);
	GHAssertEqualStrings(@"schacon@gmail.com", c.email, nil);
}

- (void)testCanWriteTagData {
	
	NSError *error = nil;
	NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH()] error:&error];
	GTTag *tag = (GTTag *)[repo lookupBySha:sha error:&error];
	
	tag.message = @"new message";
	[tag writeAndReturnError:&error];
	
	GHAssertNil(error, [error localizedDescription]);
	GHAssertNotEqualStrings(tag.sha, sha, nil);
	
	rm_loose(tag.sha);
}

@end
