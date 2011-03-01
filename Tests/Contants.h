/*
 *  Contants.h
 *  ObjectiveGitFramework
 *
 *  Created by Timothy Clem on 2/24/11.
 *  Copyright 2011 GitHub Inc. All rights reserved.
 *
 */

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

static NSString *TEST_REPO_PATH = @"file://localhost/Volumes/GitHub/Mac/ObjectiveGitFramework/Tests/fixtures/testrepo.git";
static NSString *TEST_INDEX_PATH = @"file://localhost/Volumes/GitHub/Mac/ObjectiveGitFramework/Tests/fixtures/testrepo.git/index";

static inline void rm_loose(NSString *sha){
	
	NSError *error;
	NSFileManager *m = [[NSFileManager alloc] init];
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
