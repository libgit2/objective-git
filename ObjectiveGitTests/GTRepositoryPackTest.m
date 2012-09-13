//
//  GTRepositoryPackTest.m
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


@interface GTRepositoryPackTest : SenTestCase {
	
	GTRepository *repo;
}
@end

@implementation GTRepositoryPackTest

- (void)setUp {
	
	NSError *error = nil;
	repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
}

//- (void)testCanTellIfPackedObjectExists {
//	
//	NSError *error = nil;
//	STAssertTrue([repo.objectDatabase containsObjectWithSha:@"41bc8c69075bbdb46c5c6f0566cc8cc5b46e8bd9" error:&error], nil);
//	STAssertTrue([repo.objectDatabase containsObjectWithSha:@"f82a8eb4cb20e88d1030fd10d89286215a715396" error:&error], nil);
//}

//- (void)testCanReadAPackedObjectFromDb {
//	
//	NSError *error = nil;
//	GTOdbObject *obj = [repo.objectDatabase objectWithSha:@"41bc8c69075bbdb46c5c6f0566cc8cc5b46e8bd9" error:&error];
//	
//	STAssertEquals(230, (int)[obj.data length], nil);
//	STAssertEquals(GTObjectTypeCommit, obj.type, nil);
//}

@end
