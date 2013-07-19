//
//  NSError+GitTest.m
//  ObjectiveGitFramework
//
//  Created by Stephan Diederich on 19.07.13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSData+Git.h"

@interface NSError_GitTest : SenTestCase
@end

@implementation NSError_GitTest

- (void) testThatErrorIsCreated {
	NSError *error = [NSError git_errorFor:0];
	STAssertNotNil(error, @"Failed to create error");
}

//regression - this NSError creation is used in + (id)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error
- (void) testThatFileURLsWithSpacesDontCrashInErrorCreation {
	
	NSURL *localFileURL = [NSURL fileURLWithPath:@"/Peter Pan/"];
	NSError *error = [NSError git_errorFor:0 withAdditionalDescription:@"Failed to open repository at URL %@.", localFileURL];

	STAssertNotNil(error, @"Should have been created");
}
@end
