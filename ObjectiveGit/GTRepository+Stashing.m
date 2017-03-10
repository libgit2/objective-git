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

#import "git2/errors.h"

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

static int stashApplyProgressCallback(git_stash_apply_progress_t progress, void *payload) {
	void (^block)(GTRepositoryStashApplyProgress, BOOL *) = (__bridge id)payload;

	BOOL stop = NO;
	block((GTRepositoryStashApplyProgress)progress, &stop);

	return (stop ? GIT_EUSER : 0);
}

- (BOOL)applyStashAtIndex:(NSUInteger)index flags:(GTRepositoryStashApplyFlag)flags checkoutOptions:(GTCheckoutOptions *)options error:(NSError **)error progressBlock:(void (^)(GTRepositoryStashApplyProgress progress, BOOL *stop))progressBlock {
	git_stash_apply_options stash_options = GIT_STASH_APPLY_OPTIONS_INIT;

	stash_options.flags = (git_stash_apply_flags)flags;

	if (progressBlock != nil) {
		stash_options.progress_cb = stashApplyProgressCallback;
		stash_options.progress_payload = (__bridge void *)progressBlock;
	}

	if (options != nil) {
		stash_options.checkout_options = *options.git_checkoutOptions;
	}

	int gitError = git_stash_apply(self.git_repository, index, &stash_options);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Stash apply failed" failureReason:@"The stash at index %ld couldn't be applied.", (unsigned long)index];
		return NO;
	}
	return YES;
}

- (BOOL)popStashAtIndex:(NSUInteger)index flags:(GTRepositoryStashApplyFlag)flags checkoutOptions:(GTCheckoutOptions *)options error:(NSError **)error progressBlock:(void (^)(GTRepositoryStashApplyProgress progress, BOOL *stop))progressBlock {
	git_stash_apply_options stash_options = GIT_STASH_APPLY_OPTIONS_INIT;

	stash_options.flags = (git_stash_apply_flags)flags;

	if (progressBlock != nil) {
		stash_options.progress_cb = stashApplyProgressCallback;
		stash_options.progress_payload = (__bridge void *)progressBlock;
	}

	if (options != nil) {
		stash_options.checkout_options = *options.git_checkoutOptions;
	}

	int gitError = git_stash_pop(self.git_repository, index, &stash_options);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Stash pop failed" failureReason:@"The stash at index %ld couldn't be applied.", (unsigned long)index];
		return NO;
	}
	return YES;
}

- (BOOL)dropStashAtIndex:(NSUInteger)index error:(NSError **)error {
	int gitError = git_stash_drop(self.git_repository, index);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Stash drop failed" failureReason:@"The stash at index %ld couldn't be dropped", (unsigned long)index];
		return NO;
	}

	return YES;
}

@end
