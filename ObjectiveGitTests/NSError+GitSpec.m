//
//  NSError+GitSpec.m
//  ObjectiveGitFramework
//
//  Created by Stephan Diederich on 19.07.13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSError+Git.h"
SpecBegin(NSErrorGit)

describe(@"NSError+Git initialisation", ^{
	it(@"should be instantiable with a description", ^{
		NSError *error = [NSError git_errorFor:0 withAdditionalDescription:@""];
		expect(error).toNot.beNil();
	});
	
	it(@"should not crash with escaped urls in description", ^{
		//regression - this NSError creation is used in + (id)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error
		NSURL *localFileURL = [NSURL fileURLWithPath:@"/Peter Pan/"];
		NSError *error = [NSError git_errorFor:0 withAdditionalDescription:@"Failed to open repository at URL %@.", localFileURL];
		
		expect(error).toNot.beNil();
	});
});

SpecEnd
