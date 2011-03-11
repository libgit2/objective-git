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

@interface GTTreeTest : GHTestCase {
	
	GTRepository *repo;
	NSString *sha;
	GTTree *tree;
}
@end

@implementation GTTreeTest

- (void)setUp {
	
	NSError *error = nil;
	repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	sha = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";
	tree = (GTTree *)[repo lookupBySha:sha error:&error];
}

- (void)testCanReadTreeData {
	
	GHAssertEqualStrings(sha, tree.sha, nil);
	GHAssertEqualStrings(@"tree", tree.type, nil);
	GHAssertTrue([tree entryCount] == 3, nil);
	GHAssertEqualStrings(@"1385f264afb75a56a5bec74243be9b367ba4ca08", [tree entryAtIndex:0].sha, nil);
	GHAssertEqualStrings(@"fa49b077972391ad58037050f2a75f74e3671e92", [tree entryAtIndex:1].sha, nil);
}

- (void)testCanReadTreeEntryData {
	
	NSError	*error = nil;
	GTTreeEntry *bent = [tree entryAtIndex:0];
	GTTreeEntry *tent = [tree entryAtIndex:2];
	
	GTObject *bentObj = [bent toObjectAndReturnError:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEqualStrings(@"README", bent.name, nil);
	GHAssertEqualStrings(bentObj.sha, bent.sha, nil);
	
	GTObject *tentObj = [tent toObjectAndReturnError:&error];
	GHAssertNil(error, [error localizedDescription]);
	GHAssertEqualStrings(@"subdir", tent.name, nil);
	GHAssertEqualStrings(@"619f9935957e010c419cb9d15621916ddfcc0b96", tentObj.sha, nil);
	GHAssertEqualStrings(@"tree", tentObj.type, nil);
}

@end
