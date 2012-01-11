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
#import "GTRepository.h"
#import "NSError+Git.h"
#import "NSString+Git.h"


@implementation GTReference

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> type: %@, repository: %@", NSStringFromClass([self class]), self, self.type, self.repository];
}

- (void)dealloc {
	self.repository = nil;
	if(self.git_reference != NULL) git_reference_free(self.git_reference);
}


#pragma mark API

@synthesize git_reference;
@synthesize repository;

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
		if(gitError < GIT_SUCCESS) {
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
		if (git_oid_fromstr(&oid, [theTarget UTF8String]) == GIT_SUCCESS) {
			gitError = git_reference_create_oid(&git_reference, 
												self.repository.git_repository, 
												[refName UTF8String], 
												&oid,
												0);
		}
		else {
			gitError = git_reference_create_symbolic(&git_reference, 
													 self.repository.git_repository, 
													 [refName UTF8String], 
													 [theTarget UTF8String],
													 0);
		}
		
		if(gitError < GIT_SUCCESS) {
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
		if(gitError < GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to resolve reference."];
			return nil;
		}
		self.repository = symbolicRef.repository;
	}
	return self;
}

- (NSString *)name {
	const char *refName = git_reference_name(self.git_reference);
	if(refName == NULL) return nil;
	
	return [NSString stringWithUTF8String:refName];
}
- (BOOL)setName:(NSString *)newName error:(NSError **)error {
	int gitError = git_reference_rename(self.git_reference, [newName UTF8String], 0);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to rename reference."];
		return NO;
	}
	return YES;
}

- (NSString *)type {
	return [NSString stringWithUTF8String:git_object_type2string((git_otype)git_reference_type(self.git_reference))];
}

- (NSString *)target {
	if(git_reference_type(self.git_reference) == GIT_REF_OID) {
		return [NSString git_stringWithOid:git_reference_oid(self.git_reference)];
	}
	else {
		return [NSString stringWithUTF8String:git_reference_target(self.git_reference)];
	}
}

- (BOOL)setTarget:(NSString *)newTarget error:(NSError **)error {	
	int gitError;
	
	if(git_reference_type(self.git_reference) == GIT_REF_OID) {
		git_oid oid;
		gitError = git_oid_fromstr(&oid, [newTarget UTF8String]);
		if(gitError < GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError git_errorForMkStr:gitError];
			return NO;
		}
		
		gitError = git_reference_set_oid(self.git_reference, &oid);
	}
	else {
		gitError = git_reference_set_target(self.git_reference, [newTarget UTF8String]);
	}

	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to set reference target."];
		return NO;
	}
	return YES;
}

- (BOOL)packAllWithError:(NSError **)error {
	int gitError = git_reference_packall(self.repository.git_repository);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to pack all references in repo."];
		return NO;
	}
	return YES;
}

- (BOOL)deleteWithError:(NSError **)error {
	int gitError = git_reference_delete(self.git_reference);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to delete reference."];
		return NO;
	}
	self.git_reference = NULL; /* this has been free'd */
	return YES;
}

- (GTReference *)resolvedReferenceWithError:(NSError **)error {
	return [GTReference referenceByResolvingSymbolicReference:self error:error];
}

- (const git_oid *)oid {
	return git_reference_oid(self.git_reference);
}

- (BOOL)reloadWithError:(NSError **)error {
	int errorCode = git_reference_reload(self.git_reference);
	if(errorCode < GIT_SUCCESS) {
		if(error != NULL) {
			*error = [NSError git_errorFor:errorCode withAdditionalDescription:@"Failed to reload reference."];
		}
		
		self.git_reference = NULL;
		
		return NO;
	}
	
	return YES;
}

- (BOOL)isValid {
	return self.git_reference != NULL;
}

@end
