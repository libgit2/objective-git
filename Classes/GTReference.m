//
//  GTReference.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/2/11.
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

#import "GTReference.h"
#import "GTOID.h"
#import "GTReflog+Private.h"
#import "GTRepository.h"
#import "GTObject+Private.h"
#import "NSError+Git.h"
#import "NSString+Git.h"

@interface GTReference ()
@property (nonatomic, readonly, assign) git_reference *git_reference;
@end

static NSString *referenceTypeToString(GTReferenceType type) {
	switch (type) {
		case GTReferenceTypeInvalid:
			return @"invalid";

		case GTReferenceTypeOid:
			return @"direct";

		case GTReferenceTypeSymbolic:
			return @"symbolic";
	}
	return @"unknown";
}

@implementation GTReference

#pragma mark -
#pragma mark Class methods

+ (NSError *)invalidReferenceError {
	return [NSError git_errorFor:GTReferenceErrorCodeInvalidReference description:@"Invalid git_reference."];
}

+ (BOOL)isValidReferenceName:(NSString *)refName {
	return git_reference_is_valid_name(refName.UTF8String) == 1;
}

+ (id)referenceByLookingUpReferenceNamed:(NSString *)referenceName inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(referenceName != nil);
	NSParameterAssert(repository != nil);

	git_reference *ref = NULL;
	int gitError = git_reference_lookup(&ref, repository.git_repository, referenceName.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Reference lookup failed" failureReason:@"The reference named \"%@\" couldn't be resolved in \"%@\"", referenceName, repository.gitDirectoryURL.path];
		return nil;
	}

	return [[self alloc] initWithGitReference:ref repository:repository];
}

+ (id)referenceByCreatingReferenceNamed:(NSString *)referenceName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(referenceName != nil);
	NSParameterAssert(target != nil);
	NSParameterAssert(repository != nil);

	GTOID *oid = [GTOID oidWithSHA:target];
	int gitError = GIT_OK;
	git_reference *ref;
	if (oid != nil) {
		gitError = git_reference_create(&ref, repository.git_repository, referenceName.UTF8String, oid.git_oid, 0);
	} else {
		gitError = git_reference_symbolic_create(&ref, repository.git_repository, referenceName.UTF8String, target.UTF8String, 0);
	}

	if (gitError != GIT_OK) {
		if(error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create symbolic reference to %@.", target];
		return nil;
	}

	return [[self alloc] initWithGitReference:ref repository:repository];
}

+ (id)referenceByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error {
	NSParameterAssert(symbolicRef != nil);

	git_reference *ref = NULL;
	int gitError = git_reference_resolve(&ref, symbolicRef.git_reference);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to resolve reference %@.", symbolicRef.name];
		return nil;
	}

	return [[self alloc] initWithGitReference:ref repository:symbolicRef.repository];
}

- (id)initWithGitReference:(git_reference *)ref repository:(GTRepository *)repo {
	NSParameterAssert(ref != NULL);
	NSParameterAssert(repo != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_reference = ref;
	_repository = repo;

	return self;
}

- (void)dealloc {
	if (_git_reference != NULL) {
		git_reference_free(_git_reference);
		_git_reference = NULL;
	}
}

#pragma mark -
#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ OID: %@, type: %@, remote: %i }", self.class, self, self.OID, referenceTypeToString(self.referenceType), (int)self.remote];
}

- (NSUInteger)hash {
	return self.name.hash;
}

- (BOOL)isEqual:(GTReference *)reference {
	if (self == reference) return YES;
	if (![reference isKindOfClass:GTReference.class]) return NO;

	return [self.repository isEqual:reference.repository] && [self.name isEqual:reference.name] && [self.unresolvedTarget isEqual:reference.unresolvedTarget];
}

#pragma mark -
#pragma mark Properties

- (BOOL)isBranch {
	return git_reference_is_branch(self.git_reference) != 0;
}

- (BOOL)isTag {
	return git_reference_is_tag(self.git_reference) != 0;
}

- (BOOL)isRemote {
	return git_reference_is_remote(self.git_reference) != 0;
}

- (NSString *)name {
	const char *refName = git_reference_name(self.git_reference);
	if (refName == NULL) return nil;
	
	return @(refName);
}

- (const git_oid *)git_oid {
	return git_reference_target(self.git_reference);
}

- (GTOID *)OID {
	const git_oid *oid = self.git_oid;
	if (oid == NULL) return nil;

	return [[GTOID alloc] initWithGitOid:oid];
}

- (GTReferenceType)referenceType {
	return (GTReferenceType)git_reference_type(self.git_reference);
}

- (id)unresolvedTarget {
	if (self.referenceType == GTReferenceTypeOid) {
		const git_oid *oid = git_reference_target(self.git_reference);
		if (oid == NULL) return nil;

		return [GTObject lookupWithGitOID:oid inRepository:self.repository error:NULL];
	} else if (self.referenceType == GTReferenceTypeSymbolic) {
		NSString *refName = @(git_reference_symbolic_target(self.git_reference));
		if (refName == NULL) return nil;

		return [self.class referenceByLookingUpReferenceNamed:refName inRepository:self.repository error:NULL];
	}
	return nil;
}

- (id)resolvedTarget {
	git_object *obj;
	git_reference_peel(&obj, self.git_reference, GIT_OBJ_ANY);
	if (obj == NULL) return nil;

	return [GTObject objectWithObj:obj inRepository:self.repository];
}

- (GTReference *)resolvedReference {
	return [self.class referenceByResolvingSymbolicReference:self error:NULL];
}

- (NSString *)targetSHA {
	return [self.resolvedTarget SHA];
}

- (GTReflog *)reflog {
	return [[GTReflog alloc] initWithReference:self];
}


#pragma mark -
#pragma mark API

- (GTReference *)referenceByRenaming:(NSString *)newName error:(NSError **)error {
	NSParameterAssert(newName != nil);

	git_reference *newRef = NULL;
	int gitError = git_reference_rename(&newRef, self.git_reference, newName.UTF8String, 0);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to rename reference %@ to %@.", self.name, newName];
		return NO;
	}

	return [[self.class alloc] initWithGitReference:newRef repository:self.repository];
}

- (GTReference *)referenceByUpdatingTarget:(NSString *)newTarget error:(NSError **)error {
	NSParameterAssert(newTarget != nil);

	int gitError;
	git_reference *newRef = NULL;
	if (git_reference_type(self.git_reference) == GIT_REF_OID) {
		GTOID *oid = [[GTOID alloc] initWithSHA:newTarget error:error];
		if (oid == nil) return nil;
		
		gitError = git_reference_set_target(&newRef, self.git_reference, oid.git_oid);
	} else {
		gitError = git_reference_symbolic_set_target(&newRef, self.git_reference, newTarget.UTF8String);
	}

	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to update reference %@ to target %@.", self.name, newTarget];
		return nil;
	}

	return [[self.class alloc] initWithGitReference:newRef repository:self.repository];
}

- (BOOL)deleteWithError:(NSError **)error {
	int gitError = git_reference_delete(self.git_reference);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to delete reference %@.", self.name];
		return NO;
	}

	return YES;
}

- (GTReference *)resolvedReferenceWithError:(NSError **)error {
	return [GTReference referenceByResolvingSymbolicReference:self error:error];
}

- (GTReference *)reloadedReferenceWithError:(NSError **)error {
	return [self.class referenceByLookingUpReferenceNamed:self.name inRepository:self.repository error:error];
}

@end
