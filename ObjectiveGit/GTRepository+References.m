//
//  GTRepository+References.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 6/4/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import "GTRepository+References.h"
#import "GTReference.h"
#import "NSError+Git.h"

#import "git2/errors.h"

@implementation GTRepository (References)

- (GTReference *)lookUpReferenceWithName:(NSString *)name error:(NSError **)error {
	NSParameterAssert(name != nil);

	git_reference *ref = NULL;
	int gitError = git_reference_lookup(&ref, self.git_repository, name.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to lookup reference %@.", name];
		return nil;
	}

	return [[GTReference alloc] initWithGitReference:ref repository:self];
}

@end
