//
//  GTRepository+Reset.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/4/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Reset.h"
#import "GTCommit.h"
#import "NSArray+StringArray.h"
#import "NSError+Git.h"
#import "GTSignature.h"

@implementation GTRepository (Reset)

- (BOOL)resetToCommit:(GTCommit *)commit resetType:(GTRepositoryResetType)resetType error:(NSError **)error {
	NSParameterAssert(commit != nil);

	int gitError = git_reset(self.git_repository, commit.git_object, (git_reset_t)resetType, (git_signature *)[self userSignatureForNow].git_signature, NULL);
	if (gitError != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to reset repository to commit %@.", commit.SHA];
		}

		return NO;
	}

	return YES;
}

- (BOOL)resetPathspecs:(NSArray *)paths toCommit:(GTCommit *)commit error:(NSError **)error {
	NSParameterAssert(paths != nil);
	NSParameterAssert(commit != nil);

	git_strarray array = paths.git_strarray;
	int gitError = git_reset_default(self.git_repository, commit.git_object, &array);
	if (gitError != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed resetting paths (%@) to %@", paths, commit];
		}

		return NO;
	}

	return YES;
}

@end
