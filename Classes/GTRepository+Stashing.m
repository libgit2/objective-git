//
//  GTRepository+Stashing.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-09-27.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Stashing.h"
#import "GTOID.h"
#import "GTRepository+Private.h"
#import "GTSignature.h"
#import "NSError+Git.h"

typedef void (^GTRepositoryStashEnumerationBlock)(NSUInteger index, NSString *message, GTOID *oid, BOOL *stop);

@implementation GTRepository (Stashing)

- (GTCommit *)stashChangesWithMessage:(NSString *)message flags:(GTRepositoryStashFlag)flags error:(NSError **)error {
	git_oid git_oid;

	int gitError = git_stash_save(&git_oid, self.git_repository, [self userSignatureForNow].git_signature, message.UTF8String, flags);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to stash."];
		return nil;
	}
	
	return [self lookUpObjectByGitOid:&git_oid error:error];
}

static int stashEnumerationCallback(size_t index, const char *message, const git_oid *stash_id, void *payload) {
	GTRepositoryStashEnumerationBlock block = (__bridge GTRepositoryStashEnumerationBlock)payload;
	
	NSString *messageString = nil;
	if (message != NULL) messageString = @(message);

	GTOID *stashOID = [[GTOID alloc] initWithGitOid:stash_id];

	BOOL stop = NO;
	block(index, messageString, stashOID, &stop);
	
	return (stop ? GIT_EUSER : 0);
}

- (void)enumerateStashesUsingBlock:(GTRepositoryStashEnumerationBlock)block {
	NSParameterAssert(block != nil);
	
	git_stash_foreach(self.git_repository, &stashEnumerationCallback, (__bridge void *)block);
}

- (BOOL)dropStashAtIndex:(NSUInteger)index error:(NSError **)error {
	int gitError = git_stash_drop(self.git_repository, index);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to drop stash."];
		return NO;
	}

	return YES;
}

@end
