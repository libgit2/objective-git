//
//  GTWalkerTest.m
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

#import "Contants.h"


@interface GTWalkerTest : SenTestCase {}
@end

@implementation GTWalkerTest

- (void)testCanWalkSimpleRevlist {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	BOOL success = [repo.enumerator push:@"9fd738e8f7967c078dceed8190330fc8648ee56a" error:&error];
	STAssertTrue(success, [error localizedDescription]);
	
	NSMutableArray *shas = [NSMutableArray arrayWithCapacity:4];
	for (int i=0; i < 4; i++) {
		GTCommit *c = [repo.enumerator nextObjectWithError:&error];
		[shas addObject:c.sha];
		NSLog(@"%@", c.sha);
	}
	
	STAssertEqualObjects([[shas objectAtIndex:0] substringToIndex:5], @"9fd73", nil);
	STAssertEqualObjects([[shas objectAtIndex:1] substringToIndex:5], @"4a202", nil);
	STAssertEqualObjects([[shas objectAtIndex:2] substringToIndex:5], @"5b5b0", nil);
	STAssertEqualObjects([[shas objectAtIndex:3] substringToIndex:5], @"84960", nil);
	
	STAssertNil([repo.enumerator nextObjectWithError:&error], nil);
}

- (void)testCanWalkFromHead {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	STAssertNil(error, [error localizedDescription]);
	GTReference *head = [repo headReferenceWithError:&error];
	STAssertNil(error, [error localizedDescription]);
				
	__block int count = 0;
    [repo enumerateCommitsBeginningAtSha:head.target error:&error usingBlock:^(GTCommit *commit, BOOL *stop) {
        count++;
    }];
	STAssertNil(error, [error localizedDescription]);
	STAssertEquals(3, count, nil);
}

- (void)testCanWalkFromHeadShortcut {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	
	__block int count = 0;
    [repo enumerateCommitsBeginningAtSha:nil error:&error usingBlock:^(GTCommit *commit, BOOL *stop) {
        count++;
    }];
	STAssertNil(error, [error localizedDescription]);
	STAssertEquals(3, count, nil);
}

- (void)testCanWalkPartOfARevList {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	NSString *sha = @"8496071c1b46c854b31185ea97743be6a8774479";
	BOOL success = [repo.enumerator push:sha error:&error];
	STAssertTrue(success, [error localizedDescription]);
	
	STAssertEqualObjects([[repo.enumerator nextObjectWithError:&error] sha], sha, nil);
	STAssertNil([repo.enumerator nextObjectWithError:&error], nil);
}

- (void)testCanHidePartOfAList {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	BOOL success = [repo.enumerator push:@"9fd738e8f7967c078dceed8190330fc8648ee56a" error:&error];
	STAssertTrue(success, [error localizedDescription]);
	success = [repo.enumerator skipCommitWithHash:@"5b5b025afb0b4c913b4c338a42934a3863bf3644" error:&error];
	STAssertTrue(success, [error localizedDescription]);
	
	for(int i=0; i < 2; i++) {
		STAssertNotNil([repo.enumerator nextObjectWithError:&error], nil);
	}
	
	STAssertNil([repo.enumerator nextObjectWithError:&error], nil);
}

- (void)testCanResetAWalker {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	NSString *sha = @"8496071c1b46c854b31185ea97743be6a8774479";
	BOOL success = [repo.enumerator push:sha error:&error];
	STAssertTrue(success, nil);
	STAssertEqualObjects([[repo.enumerator nextObjectWithError:&error] sha], sha, nil);
	STAssertNil([repo.enumerator nextObjectWithError:&error], nil);
	
	[repo.enumerator reset];
	
	success = [repo.enumerator push:sha error:&error];
	STAssertTrue(success, [error localizedDescription]);
	STAssertEqualObjects([[repo.enumerator nextObjectWithError:&error] sha], sha, nil);
}

- (NSMutableArray *)revListWithSorting:(unsigned int)sortMode {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	NSString *sha = @"a4a7dce85cf63874e984719f4fdd239f5145052f";
	[repo.enumerator setOptions:sortMode];
	BOOL success = [repo.enumerator push:sha error:&error];
	STAssertTrue(success, [error localizedDescription]);
	
	NSMutableArray *commits = [[NSMutableArray alloc] initWithCapacity:6];
	for(int i=0; i < 6; i++) {
		[commits addObject:[repo.enumerator nextObjectWithError:&error]];
	}
	return commits;
}

- (void)sort:(NSArray *)expectedShas mode:(unsigned int)sortMode {
	
	NSMutableArray *commits = [self revListWithSorting:sortMode];
	for(int i=0; i < 6; i++) {
		GTCommit *commit = [commits objectAtIndex:i];
		STAssertEqualObjects([commit.sha substringToIndex:5], [expectedShas objectAtIndex:i],nil);
	}
}

- (void)testCanSortByDate {
	
	NSArray *expectedShas = [NSArray arrayWithObjects:
							 @"a4a7d", 
							 @"c4780",
							 @"9fd73",
							 @"4a202",
							 @"5b5b0",
							 @"84960",
							 nil];
	[self sort:expectedShas mode:GIT_SORT_TIME];
}

- (void)testCanSortByDateReverse {
	
	NSArray *expectedShas = [NSArray arrayWithObjects:
							 @"84960",
							 @"5b5b0",
							 @"4a202",
							 @"9fd73",
							 @"c4780",
							 @"a4a7d", 
							 nil];
	[self sort:expectedShas mode:GIT_SORT_TIME | GIT_SORT_REVERSE];
}

//- (void)testCanSortByTopo {
//
//	NSMutableArray *commits = [self revListWithSorting:GIT_SORT_TOPOLOGICAL];
//	
//	for(GTCommit *commit in commits) {
//		for(GTCommit *parent in commit.parents) {
//			STAssertTrue([commits indexOfObject:commit] < [commits indexOfObject:parent], nil);
//		}
//	}		
//}

//- (void)testCanSortByTopoReverse {
//	
//	NSMutableArray *commits = [self revListWithSorting:GIT_SORT_TOPOLOGICAL | GIT_SORT_REVERSE];
//	
//	for(GTCommit *commit in commits) {
//		for(GTCommit *parent in commit.parents) {
//			STAssertTrue([commits indexOfObject:commit] > [commits indexOfObject:parent], nil);
//		}
//	}		
//}

@end
