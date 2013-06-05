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
#import "NSError+Git.h"
#import "NSString+Git.h"

@interface GTReference ()

@property (nonatomic, readwrite) git_reference *git_reference;

@property (nonatomic, readwrite, strong) GTReflog *reflog;

@end

@implementation GTReference

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> type: %@, repository: %@", NSStringFromClass([self class]), self, self.type, self.repository];
}

- (void)dealloc {
	self.repository = nil;

	if(self.git_reference != NULL) {
		git_reference_free(self.git_reference);
		self.git_reference = NULL;
	}
}


#pragma mark API

@synthesize git_reference;
@synthesize repository;

- (BOOL)isRemote {
	return git_reference_is_remote(self.git_reference) != 0;
}

+ (id)referenceByLookingUpReferencedNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error {
	return [[self alloc] initByLookingUpReferenceNamed:refName inRepository:theRepo error:error];
}

+ (id)referenceByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)theRepo error:(NSError **)error {
	return [[self alloc] initByCreatingReferenceNamed:refName fromReferenceTarget:target inRepository:theRepo error:error];
}

+ (id)referenceByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error {	
	return [[self alloc] initByResolvingSymbolicReference:symbolicRef error:error];
}

- (id)initByLookingUpReferenceNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error {
	if((self = [super init])) {
		self.repository = theRepo;
		int gitError = git_reference_lookup(&git_reference, self.repository.git_repository, [refName UTF8String]);
		if(gitError < GIT_OK) {
			if(error != NULL)
				*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to lookup reference."];
			return nil;
		}
	}
	return self;
}

- (id)initByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)theTarget inRepository:(GTRepository *)theRepo error:(NSError **)error {
	if((self = [super init])) {
		git_oid oid;
		int gitError;
		
		self.repository = theRepo;
		if (git_oid_fromstr(&oid, [theTarget UTF8String]) == GIT_OK) {
			gitError = git_reference_create(&git_reference,
											self.repository.git_repository,
											[refName UTF8String],
											&oid,
											0);
		}
		else {
			gitError = git_reference_symbolic_create(&git_reference,
													 self.repository.git_repository, 
													 [refName UTF8String], 
													 [theTarget UTF8String],
													 0);
		}
		
		if(gitError < GIT_OK) {
			if(error != NULL)
				*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to create symbolic reference."];
			return nil;
		}
	}
	return self;
}

- (id)initByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error {
	if((self = [super init])) {
		int gitError = git_reference_resolve(&git_reference, symbolicRef.git_reference);
		if(gitError < GIT_OK) {
			if(error != NULL)
				*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to resolve reference."];
			return nil;
		}
		self.repository = symbolicRef.repository;
	}
	return self;
}

- (id)initWithGitReference:(git_reference *)ref repository:(GTRepository *)repo {
	self = [super init];
	if (self == nil) return nil;

	self.git_reference = ref;
	self.repository = repo;

	return self;
}

- (NSString *)name {
	if(![self isValid]) return nil;
	
	const char *refName = git_reference_name(self.git_reference);
	if(refName == NULL) return nil;
	
	return [NSString stringWithUTF8String:refName];
}

- (BOOL)setName:(NSString *)newName error:(NSError **)error {
	if(![self isValid]) {
		if(error != NULL) {
			*error = [[self class] invalidReferenceError];
		}
		
		return NO;
	}
	
	git_reference *newRef = NULL;
	int gitError = git_reference_rename(&newRef, self.git_reference, newName.UTF8String, 0);
	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to rename reference."];

		return NO;
	}

	self.git_reference = newRef;
	return YES;
}

- (NSString *)type {
	if(![self isValid]) return nil;
	
	return [NSString stringWithUTF8String:git_object_type2string((git_otype)git_reference_type(self.git_reference))];
}

- (NSString *)target {
	if(![self isValid]) return nil;
	
	if(git_reference_type(self.git_reference) == GIT_REF_OID) {
		return [NSString git_stringWithOid:git_reference_target(self.git_reference)];
	} else {
		return [NSString stringWithUTF8String:git_reference_symbolic_target(self.git_reference)];
	}
}

- (BOOL)setTarget:(NSString *)newTarget error:(NSError **)error {
	if(![self isValid]) {
		if(error != NULL) {
			*error = [[self class] invalidReferenceError];
		}
		
		return NO;
	}
	
	int gitError;
	
	git_reference *newRef = NULL;
	if(git_reference_type(self.git_reference) == GIT_REF_OID) {
		git_oid oid;
		gitError = git_oid_fromstr(&oid, [newTarget UTF8String]);
		if(gitError < GIT_OK) {
			if(error != NULL)
				*error = [NSError git_errorForMkStr:gitError];
			return NO;
		}
		
		gitError = git_reference_set_target(&newRef, self.git_reference, &oid);
	} else {
		gitError = git_reference_symbolic_set_target(&newRef, self.git_reference, newTarget.UTF8String);
	}

	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to set reference target."];
		return NO;
	}

	self.git_reference = newRef;
	return YES;
}

- (BOOL)deleteWithError:(NSError **)error {
	if(![self isValid]) {
		if(error != NULL) {
			*error = [[self class] invalidReferenceError];
		}
		
		return NO;
	}
	
	int gitError = git_reference_delete(self.git_reference);
	self.git_reference = NULL; /* this has been free'd */

	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to delete reference."];
		return NO;
	}

	return YES;
}

- (GTReference *)resolvedReferenceWithError:(NSError **)error {
	return [GTReference referenceByResolvingSymbolicReference:self error:error];
}

- (const git_oid *)git_oid {
	if (![self isValid]) return nil;
	
	return git_reference_target(self.git_reference);
}

- (GTOID *)OID {
	const git_oid *oid = self.git_oid;
	if (oid == NULL) return nil;

	return [[GTOID alloc] initWithGitOid:oid];
}

- (BOOL)reloadWithError:(NSError **)error {
	if (![self isValid]) {
		if(error != NULL) {
			*error = self.class.invalidReferenceError;
		}
		
		return NO;
	}

	git_reference *newRef = NULL;
	int errorCode = git_reference_lookup(&newRef, self.repository.git_repository, self.name.UTF8String);
	if (errorCode < GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:errorCode withAdditionalDescription:@"Failed to reload reference."];
		}
		
		return NO;
	}
	
	// TODO: Mutability sucks!
	self.git_reference = newRef;
	return YES;
}

- (BOOL)isValid {
	return self.git_reference != NULL;
}

+ (NSError *)invalidReferenceError {
	return [NSError git_errorFor:GTReferenceErrorCodeInvalidReference withAdditionalDescription:@"Invalid git_reference."];
}

- (GTReflog *)reflog {
	if (_reflog == nil) {
		_reflog = [[GTReflog alloc] initWithReference:self];
	}
	
	return _reflog;
}

@end
