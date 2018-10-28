//
//  GTAnnotatedCommit.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 18/12/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

#import "GTAnnotatedCommit.h"

#import "GTReference.h"
#import "GTRepository.h"
#import "GTOID.h"
#import "NSError+Git.h"

#import "git2/annotated_commit.h"

@interface GTAnnotatedCommit ()
@property (nonatomic, readonly, assign) git_annotated_commit *annotated_commit;
@end

@implementation GTAnnotatedCommit

+ (instancetype)annotatedCommitFromReference:(GTReference *)reference error:(NSError **)error {
	NSParameterAssert(reference != nil);

	git_annotated_commit *commit;
	int gitError = git_annotated_commit_from_ref(&commit, reference.repository.git_repository, reference.git_reference);
	if (gitError != 0) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Annotated commit creation failed"];
		return nil;
	}

	return [[self alloc] initWithGitAnnotatedCommit:commit];
}

+ (instancetype)annotatedCommitFromFetchHead:(NSString *)branchName url:(NSString *)remoteURL oid:(GTOID *)OID inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(branchName != nil);
	NSParameterAssert(remoteURL != nil);
	NSParameterAssert(OID != nil);
	NSParameterAssert(repository != nil);

	git_annotated_commit *commit;
	int gitError = git_annotated_commit_from_fetchhead(&commit, repository.git_repository, branchName.UTF8String, remoteURL.UTF8String, OID.git_oid);
	if (gitError != 0) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Annotated commit creation failed"];
		return nil;
	}

	return [[self alloc] initWithGitAnnotatedCommit:commit];
}

+ (instancetype)annotatedCommitFromOID:(GTOID *)OID inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(OID != nil);
	NSParameterAssert(repository != nil);

	git_annotated_commit *commit;
	int gitError = git_annotated_commit_lookup(&commit, repository.git_repository, OID.git_oid);
	if (gitError != 0) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Annotated commit creation failed"];
		return nil;
	}

	return [[self alloc] initWithGitAnnotatedCommit:commit];
}

+ (instancetype)annotatedCommitFromRevSpec:(NSString *)revSpec inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(revSpec != nil);
	NSParameterAssert(repository != nil);

	git_annotated_commit *commit;
	int gitError = git_annotated_commit_from_revspec(&commit, repository.git_repository, revSpec.UTF8String);
	if (gitError != 0) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Annotated commit creation failed"];
		return nil;
	}

	return [[self alloc] initWithGitAnnotatedCommit:commit];
}

- (instancetype)initWithGitAnnotatedCommit:(git_annotated_commit *)annotated_commit {
	NSParameterAssert(annotated_commit != NULL);

	self = [super init];
	if (!self) return nil;

	_annotated_commit = annotated_commit;

	return self;
}

- (void)dealloc {
	git_annotated_commit_free(_annotated_commit);
}

/// The underlying `git_annotated_commit` object.
- (git_annotated_commit *)git_annotated_commit {
	return _annotated_commit;
}

- (GTOID *)OID {
	return [GTOID oidWithGitOid:git_annotated_commit_id(self.git_annotated_commit)];
}

@end
