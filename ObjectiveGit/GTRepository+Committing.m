//
//  GTRepository+Committing.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/30/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Committing.h"
#import "GTRepository+Private.h"

@implementation GTRepository (Committing)

- (GTCommit *)createCommitWithTree:(GTTree *)tree message:(NSString *)message parents:(NSArray *)parents updatingReferenceNamed:(NSString *)refName error:(NSError **)error {
	NSParameterAssert(tree != nil);
	NSParameterAssert(message != nil);

	GTSignature *signature = [self userSignatureForNow];
	return [self createCommitWithTree:tree message:message author:signature committer:signature parents:parents updatingReferenceNamed:refName error:error];
}

- (GTCommit *)createCommitWithTree:(GTTree *)tree message:(NSString *)message author:(GTSignature *)author committer:(GTSignature *)committer parents:(NSArray *)parents updatingReferenceNamed:(NSString *)refName error:(NSError **)error {
	NSParameterAssert(tree != nil);
	NSParameterAssert(message != nil);
	NSParameterAssert(author != nil);
	NSParameterAssert(committer != nil);

	const git_commit **parentCommits = NULL;
	if (parents.count > 0) {
		parentCommits = calloc(parents.count, sizeof(git_commit *));
		for (NSUInteger i = 0; i < parents.count; i++){
			parentCommits[i] = [parents[i] git_commit];
		}
	}

	git_oid oid;
	int gitError = git_commit_create(&oid, self.git_repository, refName.UTF8String, author.git_signature, committer.git_signature, "UTF-8", message.UTF8String, tree.git_tree, (int)parents.count, parentCommits);

	free(parentCommits);

	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create commit in repository"];
		return nil;
	}

	return [self lookUpObjectByGitOid:&oid objectType:GTObjectTypeCommit error:error];
}

@end
