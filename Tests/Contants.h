//
//  Contants.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/24/11.
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

#import <GHUnit/GHUnit.h>
#import <git2.h>

#import "GTRepository.h"
#import "GTLib.h"
#import "GTObject.h"
#import "GTRawObject.h"
#import "GTCommit.h"
#import "GTSignature.h"
#import "GTTree.h"
#import "GTTreeEntry.h"
#import "GTWalker.h"
#import "GTBlob.h"
#import "GTTag.h"
#import "GTIndex.h"
#import "GTIndexEntry.h"
#import "GTReference.h"

static NSString *TEST_REPO_PATH = @"file://localhost/Volumes/GitHub/Mac/ObjectiveGitFramework/Tests/fixtures/testrepo.git";
static NSString *TEST_INDEX_PATH = @"file://localhost/Volumes/GitHub/Mac/ObjectiveGitFramework/Tests/fixtures/testrepo.git/index";

static inline void rm_loose(NSString *sha){
	
	NSError *error;
	NSFileManager *m = [[[NSFileManager alloc] init] autorelease];
	NSString *objDir = [NSString stringWithFormat:@"objects/%@", [sha substringToIndex:2]];
	NSURL *basePath = [[NSURL URLWithString:TEST_REPO_PATH] URLByAppendingPathComponent:objDir];
	NSURL *filePath = [basePath URLByAppendingPathComponent:[sha substringFromIndex:2]];
	
	NSLog(@"deleting file %@", filePath);
	
	[m removeItemAtURL:filePath error:&error];
	
	NSArray *contents = [m contentsOfDirectoryAtPath:[basePath path] error:&error];
	if([contents count] == 0) {
		NSLog(@"deleting dir %@", basePath);
		[m removeItemAtURL:basePath error:&error];
	}
}
