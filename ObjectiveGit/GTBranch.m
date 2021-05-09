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
#import "NSData+Git.h"

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

+ (instancetype)branchWithReference:(GTReference *)ref {
	return [[self alloc] initWithReference:ref];
}

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

- (instancetype)initWithReference:(GTReference *)ref {
	NSParameterAssert(ref != nil);

	self = [super init];
	if (self == nil) return nil;

	_reference = ref;

	return self;
}

- (NSString *)name {
	const char *charName;
	int gitError = git_branch_name(&charName, self.reference.git_reference);
	if (gitError != GIT_OK || charName == NULL) return nil;

	return @(charName);
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
	git_buf remote_name = GIT_BUF_INIT_CONST(0, NULL);
	int gitError = git_branch_remote_name(&remote_name, self.repository.git_repository, self.reference.name.UTF8String);
	if (gitError != GIT_OK) return nil;

	NSData *data = [NSData git_dataWithBuffer:&remote_name];
	return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (GTCommit *)targetCommitWithError:(NSError * __autoreleasing *)error {
	GTOID *oid = self.OID;
	if (oid == nil) {
		if (error != NULL) *error = GTReference.invalidReferenceError;
		return nil;
	}

	return [self.repository lookUpObjectByOID:oid objectType:GTObjectTypeCommit error:error];
}

- (NSUInteger)numberOfCommitsWithError:(NSError * __autoreleasing *)error {
	GTEnumerator *enumerator = [[GTEnumerator alloc] initWithRepository:self.repository error:error];
	if (enumerator == nil) return NSNotFound;

	GTOID *oid = self.OID;
	if (oid == nil) return NSNotFound;

	if (![enumerator pushSHA:oid.SHA error:error]) return NSNotFound;
	return [enumerator countRemainingObjects:error];
}

- (GTRepository *)repository {
	return self.reference.repository;
}

- (GTBranchType)branchType {
	if (self.reference.remote) {
		return GTBranchTypeRemote;
	} else {
		return GTBranchTypeLocal;
	}
}

- (BOOL)isHEAD {
	return (git_branch_is_head(self.reference.git_reference) ? YES : NO);
}

- (NSArray *)uniqueCommitsRelativeToBranch:(GTBranch *)otherBranch error:(NSError * __autoreleasing *)error {
	GTOID *oid = self.OID;
	GTOID *otherOID = otherBranch.OID;
	GTEnumerator *enumerator = [self.repository enumeratorForUniqueCommitsFromOID:oid relativeToOID:otherOID error:error];
	return [enumerator allObjectsWithError:error];
}

- (BOOL)deleteWithError:(NSError * __autoreleasing *)error {
	int gitError = git_branch_delete(self.reference.git_reference);
	if (gitError != GIT_OK) {
		if(error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to delete branch %@", self.name];
		return NO;
	}

	return YES;
}

- (BOOL)rename:(NSString *)name force:(BOOL)force error:(NSError * __autoreleasing *)error {
	git_reference *git_ref;
	int gitError = git_branch_move(&git_ref, self.reference.git_reference, name.UTF8String, (force ? 1 : 0));
	if (gitError != GIT_OK) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Rename branch failed"];
		return NO;
	}

	GTReference *renamedRef = [[GTReference alloc] initWithGitReference:git_ref repository:self.repository];
	NSAssert(renamedRef, @"Unable to allocate renamed ref");
	_reference = renamedRef;

	return YES;
}

- (GTBranch *)trackingBranchWithError:(NSError * __autoreleasing *)error success:(BOOL *)success {
	BOOL underSuccess = NO;
	if (success == NULL) {
		success = &underSuccess;
	}

	if (self.branchType == GTBranchTypeRemote) {
		*success = YES;
		return self;
	}

	git_reference *trackingRef = NULL;
	int gitError = git_branch_upstream(&trackingRef, self.reference.git_reference);

	// GIT_ENOTFOUND means no tracking branch found.
	if (gitError == GIT_ENOTFOUND) {
		*success = YES;
		return nil;
	}

	if (gitError != GIT_OK) {
		*success = NO;
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create reference to tracking branch from %@", self];
		return nil;
	}

	if (trackingRef == NULL) {
		*success = NO;
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Got a NULL remote ref for %@", self];
		return nil;
	}

	GTReference *upsteamRef = [[GTReference alloc] initWithGitReference:trackingRef repository:self.repository];
	if (upsteamRef == nil) {
		*success = NO;
		if (error != NULL) *error = [NSError git_errorFor:GIT_ERROR description:@"Failed to allocate upstream ref"];
		return nil;
	}

	*success = YES;

	return [[self class] branchWithReference:upsteamRef];
}

- (BOOL)updateTrackingBranch:(GTBranch *)trackingBranch error:(NSError * __autoreleasing *)error {
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

- (GTBranch *)reloadedBranchWithError:(NSError * __autoreleasing *)error {
	GTReference *reloadedRef = [self.reference reloadedReferenceWithError:error];
	if (reloadedRef == nil) return nil;

	return [[self.class alloc] initWithReference:reloadedRef];
}

- (BOOL)calculateAhead:(size_t *)ahead behind:(size_t *)behind relativeTo:(GTBranch *)branch error:(NSError * __autoreleasing *)error {
	GTOID *oid = self.OID;
	GTOID *branchOID = branch.OID;
	return [self.repository calculateAhead:ahead behind:behind ofOID:oid relativeToOID:branchOID error:error];
}

@end
