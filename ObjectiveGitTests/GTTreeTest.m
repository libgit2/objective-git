//
//  GTTreeTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/25/11.
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


@interface GTTreeTest : SenTestCase {
	
	GTRepository *repo;
	NSString *sha;
	GTTree *tree;
}
@end

@implementation GTTreeTest

- (void)setUp {
	
	NSError *error = nil;
	repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	sha = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";
	tree = (GTTree *)[repo lookupObjectBySha:sha error:&error];
}

- (void)testCanReadTreeData {
	
	STAssertEqualObjects(sha, tree.sha, nil);
	STAssertEqualObjects(@"tree", tree.type, nil);
	STAssertTrue([tree numberOfEntries] == 3, nil);
	STAssertEqualObjects(@"1385f264afb75a56a5bec74243be9b367ba4ca08", [tree entryAtIndex:0].sha, nil);
	STAssertEqualObjects(@"fa49b077972391ad58037050f2a75f74e3671e92", [tree entryAtIndex:1].sha, nil);
}

- (void)testCanReadTreeEntryData {
	
	NSError	*error = nil;
	GTTreeEntry *bent = [tree entryAtIndex:0];
	GTTreeEntry *tent = [tree entryAtIndex:2];
	
	GTObject *bentObj = [bent toObjectAndReturnError:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertEqualObjects(@"README", bent.name, nil);
	STAssertEqualObjects(bentObj.sha, bent.sha, nil);
	
	GTObject *tentObj = [tent toObjectAndReturnError:&error];
	STAssertNil(error, [error localizedDescription]);
	STAssertEqualObjects(@"subdir", tent.name, nil);
	STAssertEqualObjects(@"619f9935957e010c419cb9d15621916ddfcc0b96", tentObj.sha, nil);
	STAssertEqualObjects(@"tree", tentObj.type, nil);
}

@end
