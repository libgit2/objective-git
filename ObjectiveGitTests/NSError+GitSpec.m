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
	it(@"should be instantiable with an additional description", ^{
		NSError *error = [NSError git_errorFor:0 withAdditionalDescription:@"Description"];
		expect(error).toNot.beNil();
	});
	
	it(@"should be instantiable without a failure reason", ^{
		NSError *error = [NSError git_errorFor:0 description:@"" failureReason:nil];
		expect(error).toNot.beNil();
	});
	
	it(@"should use its format specifier", ^{
		NSError *error = [NSError git_errorFor:0 description:@"" failureReason:@"%d",42];
		expect(error.userInfo[NSLocalizedFailureReasonErrorKey]).to.equal(@"42");
	});
});

SpecEnd
