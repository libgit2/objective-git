//
//  GTBranch.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/3/11.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "GTBranch.h"

#import "GTCommit.h"
#import "GTEnumerator.h"
#import "GTOID.h"
#import "GTReference.h"
#import "GTRemote.h"
#import "GTRepository.h"
#import "NSError+Git.h"

#import "git2/branch.h"
#import "git2/errors.h"
#import "git2/graph.h"

@implementation GTBranch

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> name: %@, shortName: %@, sha: %@, remoteName: %@, repository: %@", NSStringFromClass([self class]), self, self.name, self.shortName, self.OID, self.remoteName, self.repository];
}

- (BOOL)isEqual:(GTBranch *)otherBranch {
	if (otherBranch == self) return YES;
	if (![otherBranch isKindOfClass:self.class]) return NO;

	return [self.name isEqual:otherBranch.name] && [self.OID isEqual:otherBranch.OID];
}

- (NSUInteger)hash {
	return self.name.hash ^ self.OID.hash;
}


#pragma mark API

+ (NSString *)localNamePrefix {
	return @"refs/heads/";
}

+ (NSString *)remoteNamePrefix {
	return @"refs/remotes/";
}

+ (instancetype)branchWithReference:(GTReference *)ref repository:(GTRepository *)repo {
	return [[self alloc] initWithReference:ref repository:repo];
}

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

- (instancetype)initWithReference:(GTReference *)ref repository:(GTRepository *)repo {
	NSParameterAssert(ref != nil);
	NSParameterAssert(repo != nil);

	self = [super init];
	if (self == nil) return nil;

	_repository = repo;
	_reference = ref;

	return self;
}

- (NSString *)name {
	return self.reference.name;
}

- (NSString *)shortName {
	const char *name;
	int gitError = git_branch_name(&name, self.reference.git_reference);
	if (gitError != GIT_OK) return nil;

	if (self.branchType == GTBranchTypeRemote) {
		// Skip the initial remote name and forward slash.
		name = strchr(name, '/');
		if (name == NULL) return nil;

		name++;
	}

	return @(name);
}

- (GTOID *)OID {
	return self.reference.targetOID;
}

- (NSString *)remoteName {
	if (self.branchType == GTBranchTypeLocal) return nil;

	const char *name;
	int gitError = git_branch_name(&name, self.reference.git_reference);
	if (gitError != GIT_OK) return nil;

	// Find out where the remote name ends.
	const char *end = strchr(name, '/');
	if (end == NULL || end == name) return nil;

	return [[NSString alloc] initWithBytes:name length:end - name encoding:NSUTF8StringEncoding];
}

- (GTCommit *)targetCommitWithError:(NSError **)error {
	if (self.OID == nil) {
		if (error != NULL) *error = GTReference.invalidReferenceError;
		return nil;
	}

	return [self.repository lookUpObjectByOID:self.OID objectType:GTObjectTypeCommit error:error];
}

- (NSUInteger)numberOfCommitsWithError:(NSError **)error {
	GTEnumerator *enumerator = [[GTEnumerator alloc] initWithRepository:self.repository error:error];
	if (enumerator == nil) return NSNotFound;

	if (![enumerator pushSHA:self.OID.SHA error:error]) return NSNotFound;
	return [enumerator countRemainingObjects:error];
}

- (GTBranchType)branchType {
	if (self.reference.remote) {
		return GTBranchTypeRemote;
	} else {
		return GTBranchTypeLocal;
	}
}

- (NSArray *)uniqueCommitsRelativeToBranch:(GTBranch *)otherBranch error:(NSError **)error {
	GTEnumerator *enumerator = [self.repository enumeratorForUniqueCommitsFromOID:self.OID relativeToOID:otherBranch.OID error:error];
	return [enumerator allObjectsWithError:error];
}

- (BOOL)deleteWithError:(NSError **)error {
	int gitError = git_branch_delete(self.reference.git_reference);
	if (gitError != GIT_OK) {
		if(error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to delete branch %@", self.name];
		return NO;
	}

	return YES;
}

- (GTBranch *)trackingBranchWithError:(NSError **)error success:(BOOL *)success {
	if (self.branchType == GTBranchTypeRemote) {
		if (success != NULL) *success = YES;
		return self;
	}

	git_reference *trackingRef = NULL;
	int gitError = git_branch_upstream(&trackingRef, self.reference.git_reference);

	// GIT_ENOTFOUND means no tracking branch found.
	if (gitError == GIT_ENOTFOUND) {
		if (success != NULL) *success = YES;
		return nil;
	}

	if (gitError != GIT_OK) {
		if (success != NULL) *success = NO;
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create reference to tracking branch from %@", self];
		return nil;
	}

	if (trackingRef == NULL) {
		if (success != NULL) *success = NO;
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Got a NULL remote ref for %@", self];
		return nil;
	}

	if (success != NULL) *success = YES;

	return [[self class] branchWithReference:[[GTReference alloc] initWithGitReference:trackingRef repository:self.repository] repository:self.repository];
}

- (BOOL)updateTrackingBranch:(GTBranch *)trackingBranch error:(NSError **)error {
	int result = GIT_ENOTFOUND;
	if (trackingBranch.branchType == GTBranchTypeRemote) {
		result = git_branch_set_upstream(self.reference.git_reference, [trackingBranch.name stringByReplacingOccurrencesOfString:[GTBranch remoteNamePrefix] withString:@""].UTF8String);
	} else {
		result = git_branch_set_upstream(self.reference.git_reference, trackingBranch.shortName.UTF8String);
	}
	if (result != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:result description:@"Failed to update tracking branch for %@", self];
		return NO;
	}

	return YES;
}

- (GTBranch *)reloadedBranchWithError:(NSError **)error {
	GTReference *reloadedRef = [self.reference reloadedReferenceWithError:error];
	if (reloadedRef == nil) return nil;

	return [[self.class alloc] initWithReference:reloadedRef repository:self.repository];
}

- (BOOL)calculateAhead:(size_t *)ahead behind:(size_t *)behind relativeTo:(GTBranch *)branch error:(NSError **)error {
	return [self.repository calculateAhead:ahead behind:behind ofOID:self.OID relativeToOID:branch.OID error:error];
}

@end
