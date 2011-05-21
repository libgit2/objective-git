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

#if TARGET_OS_IPHONE
#import <GHUnitIOS/GHUnit.h>
#else
#import <GHUnit/GHUnit.h>
#endif

#import <git2.h>

#import "GTRepository.h"
#import "GTObject.h"
#import "GTObjectDatabase.h"
#import "GTOdbObject.h"
#import "GTCommit.h"
#import "GTSignature.h"
#import "GTTree.h"
#import "GTTreeEntry.h"
#import "GTEnumerator.h"
#import "GTBlob.h"
#import "GTTag.h"
#import "GTIndex.h"
#import "GTIndexEntry.h"
#import "GTReference.h"
#import "GTBranch.h"


static inline NSString *TEST_REPO_PATH(void) {
#if TARGET_OS_IPHONE
    return [NSTemporaryDirectory() stringByAppendingFormat:@"fixtures/testrepo.git"];
#else
	return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"fixtures/testrepo.git"];
#endif
}

static inline NSString *TEST_INDEX_PATH(void) {
#if TARGET_OS_IPHONE
    return [NSTemporaryDirectory() stringByAppendingFormat:@"fixtures/testrepo.git/index"];
#else
	return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"fixtures/testrepo.git/index"];
#endif
}

static inline void CREATE_WRITABLE_FIXTURES(void) {
#if TARGET_OS_IPHONE
    NSFileManager *fm = [NSFileManager defaultManager];
	
    if([fm fileExistsAtPath:TEST_REPO_PATH()])
		[fm removeItemAtPath:TEST_REPO_PATH() error:nil];
    
    NSString *repoInBundle = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"fixtures/testrepo.git"];
    
    NSString *fixturesDir = [TEST_REPO_PATH() stringByDeletingPathExtension];
    NSError *error = nil;
    [fm createDirectoryAtPath:fixturesDir withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        [NSException raise:@"Fixture Setup Error:" format:[error localizedDescription]];
    }
    
    [fm copyItemAtPath:repoInBundle toPath:TEST_REPO_PATH() error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
        [NSException raise:@"Fixture Setup Error:" format:[error localizedDescription]];
    }
    
#endif
}

static inline void rm_loose(NSString *sha) {
	
	NSError *error;
	NSFileManager *m = [[[NSFileManager alloc] init] autorelease];
	NSString *objDir = [NSString stringWithFormat:@"objects/%@", [sha substringToIndex:2]];
	NSURL *basePath = [[NSURL fileURLWithPath:TEST_REPO_PATH()] URLByAppendingPathComponent:objDir];
	NSURL *filePath = [basePath URLByAppendingPathComponent:[sha substringFromIndex:2]];
	
	NSLog(@"deleting file %@", filePath);
	
	[m removeItemAtURL:filePath error:&error];
	
	NSArray *contents = [m contentsOfDirectoryAtPath:[basePath path] error:&error];
	if([contents count] == 0) {
		NSLog(@"deleting dir %@", basePath);
		[m removeItemAtURL:basePath error:&error];
	}
}
