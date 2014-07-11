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
#import "GTRepository+Private.h"
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

- (void)dealloc {
	if (_git_reference != NULL) {
		git_reference_free(_git_reference);
		_git_reference = NULL;
	}
}


#pragma mark API

- (BOOL)isRemote {
	return git_reference_is_remote(self.git_reference) != 0;
}

+ (id)referenceByLookingUpReferencedNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error {
	return [[self alloc] initByLookingUpReferenceNamed:refName inRepository:theRepo error:error];
}

+ (id)referenceByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error {	
	return [[self alloc] initByResolvingSymbolicReference:symbolicRef error:error];
}

- (id)initByLookingUpReferenceNamed:(NSString *)refName inRepository:(GTRepository *)repo error:(NSError **)error {
	NSParameterAssert(refName != nil);
	NSParameterAssert(repo != nil);

	git_reference *ref = NULL;
	int gitError = git_reference_lookup(&ref, repo.git_repository, refName.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to lookup reference %@.", refName];
		return nil;
	}

	return [self initWithGitReference:ref repository:repo];
}

- (id)initByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error {
	NSParameterAssert(symbolicRef != nil);

	git_reference *ref = NULL;
	int gitError = git_reference_resolve(&ref, symbolicRef.git_reference);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to resolve reference %@.", symbolicRef.name];
		return nil;
	}

	return [self initWithGitReference:ref repository:symbolicRef.repository];
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

- (NSString *)name {
	const char *refName = git_reference_name(self.git_reference);
	if (refName == NULL) return nil;
	
	return @(refName);
}

- (GTReference *)referenceByRenaming:(NSString *)newName error:(NSError **)error {
	NSParameterAssert(newName != nil);
	
	git_reference *newRef = NULL;
	int gitError = git_reference_rename(&newRef, self.git_reference, newName.UTF8String, 0, [self.repository userSignatureForNow].git_signature, NULL);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to rename reference %@ to %@.", self.name, newName];
		return nil;
	}

	return [[self.class alloc] initWithGitReference:newRef repository:self.repository];
}

- (GTReferenceType)referenceType {
	return (GTReferenceType)git_reference_type(self.git_reference);
}

- (id)unresolvedTarget {
	if (self.referenceType == GTReferenceTypeOid) {
		const git_oid *oid = git_reference_target(self.git_reference);
		if (oid == NULL) return nil;

		return [self.repository lookUpObjectByGitOid:oid error:NULL];
	} else if (self.referenceType == GTReferenceTypeSymbolic) {
		NSString *refName = @(git_reference_symbolic_target(self.git_reference));
		if (refName == NULL) return nil;

		return [self.class referenceByLookingUpReferencedNamed:refName inRepository:self.repository error:NULL];
	}
	return nil;
}

- (id)resolvedTarget {
	git_object *obj;
	if (git_reference_peel(&obj, self.git_reference, GIT_OBJ_ANY) != GIT_OK) {
		return nil;
	}

	return [GTObject objectWithObj:obj inRepository:self.repository];
}

- (GTReference *)resolvedReference {
	return [self.class referenceByResolvingSymbolicReference:self error:NULL];
}

- (NSString *)targetSHA {
	return [self.resolvedTarget SHA];
}

- (GTReference *)referenceByUpdatingTarget:(NSString *)newTarget committer:(GTSignature *)signature message:(NSString *)message error:(NSError **)error {
	NSParameterAssert(newTarget != nil);

	int gitError;
	git_reference *newRef = NULL;
	if (git_reference_type(self.git_reference) == GIT_REF_OID) {
		GTOID *oid = [[GTOID alloc] initWithSHA:newTarget error:error];
		if (oid == nil) return nil;
		
		gitError = git_reference_set_target(&newRef, self.git_reference, oid.git_oid, signature.git_signature, message.UTF8String);
	} else {
		gitError = git_reference_symbolic_set_target(&newRef, self.git_reference, newTarget.UTF8String, signature.git_signature, message.UTF8String);
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

- (const git_oid *)git_oid {
	return git_reference_target(self.git_reference);
}

- (GTOID *)OID {
	const git_oid *oid = self.git_oid;
	if (oid == NULL) return nil;

	return [[GTOID alloc] initWithGitOid:oid];
}

- (GTReference *)reloadedReferenceWithError:(NSError **)error {
	return [[self.class alloc] initByLookingUpReferenceNamed:self.name inRepository:self.repository error:error];
}

+ (NSError *)invalidReferenceError {
	return [NSError git_errorFor:GTReferenceErrorCodeInvalidReference description:@"Invalid git_reference."];
}

- (GTReflog *)reflog {
	return [[GTReflog alloc] initWithReference:self];
}

+ (BOOL)isValidReferenceName:(NSString *)refName {
	return git_reference_is_valid_name(refName.UTF8String) == 1;
}

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

	return [self.name isEqual:reference.name] && [self.unresolvedTarget isEqual:reference.unresolvedTarget];
}

@end
