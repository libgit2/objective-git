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
#import "GTLib.h"
#import "NSString+Git.h"
#import "NSError+Git.h"


@implementation GTReference

- (void)dealloc {
	
	self.repository = nil;
	[super dealloc];
}

- (const git_oid *)oid {
	
	return git_reference_oid(self.ref);
}

#pragma mark -
#pragma mark API

@synthesize ref;
@synthesize repository;
@synthesize type;

- (id)initByLookingUpReferenceNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error {
	
	if((self = [super init])) {
		self.repository = theRepo;
		int gitError = git_reference_lookup(&ref, self.repository.repo, [refName UTF8String]);
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorForLookupRef:gitError];
            [self release];
			return nil;
		}
	}
	return self;
}
+ (id)referenceByLookingUpReferencedNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error {
	
	return [[[self alloc] initByLookingUpReferenceNamed:refName inRepository:theRepo error:error] autorelease];
}

- (id)initByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)theTarget inRepository:(GTRepository *)theRepo error:(NSError **)error {
	
	if((self = [super init])) {
		
		git_oid oid;
		int gitError;
		
		self.repository = theRepo;
		if (git_oid_mkstr(&oid, [theTarget UTF8String]) == GIT_SUCCESS) {
			gitError = git_reference_create_oid(&ref, 
												self.repository.repo, 
												[refName UTF8String], 
												&oid);
		}
		else {
			gitError = git_reference_create_symbolic(&ref, 
													 self.repository.repo, 
													 [refName UTF8String], 
													 [theTarget UTF8String]);
		}
		
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorForCreateRef:gitError];
            [self release];
			return nil;
		}
	}
	return self;
}
+ (id)referenceByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)theRepo error:(NSError **)error {
		
	return [[[self alloc] initByCreatingReferenceNamed:refName fromReferenceTarget:target inRepository:theRepo error:error] autorelease];
}

- (id)initByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error {
	
	if((self = [super init])) {
		
		int gitError = git_reference_resolve(&ref, symbolicRef.ref);
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorForResloveRef:gitError];
            [self release];
			return nil;
		}
		self.repository = symbolicRef.repository;
	}
	return self;
}
+ (id)referenceByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error {
	
	return [[[self alloc] initByResolvingSymbolicReference:symbolicRef error:error] autorelease];
}

- (NSString *)name {
	
	return [NSString stringForUTF8String:git_reference_name(self.ref)];
}
- (BOOL)setName:(NSString *)newName error:(NSError **)error {
	
	int gitError = git_reference_rename(self.ref, [newName UTF8String]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForRenameRef:gitError];
		return NO;
	}
	return YES;
}

- (NSString *)type {
	
	return [NSString stringForUTF8String:git_object_type2string(git_reference_type(self.ref))];
}

+ (NSArray *)referenceNamesInRepository:(GTRepository *)theRepo types:(GTReferenceTypes)types error:(NSError **)error {
	
	NSParameterAssert(theRepo != nil);
	NSParameterAssert(theRepo.repository != nil);
	
	git_strarray array;
	
	int gitError = git_reference_listall(&array, theRepo.repo, types);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForListAllRefs:gitError];
		return nil;
	}
	
	NSMutableArray *references = [NSMutableArray arrayWithCapacity:array.count];
	for(int i=0; i< array.count; i++) {
		[references addObject:[NSString stringForUTF8String:array.strings[i]]];
	}
	
	return references;
}

+ (NSArray *)referenceNamesInRepository:(GTRepository *)theRepo error:(NSError **)error {
	
	return [self referenceNamesInRepository:theRepo types:GTReferenceTypesListAll error:error];
}

- (NSString *)target {
	
	if(git_reference_type(self.ref) == GIT_REF_OID) {
		return [GTLib convertOidToSha:git_reference_oid(self.ref)];
	}
	else {
		return [NSString stringForUTF8String:git_reference_target(self.ref)];
	}
}
- (BOOL)setTarget:(NSString *)newTarget error:(NSError **)error {
	
	int gitError;
	
	if(git_reference_type(self.ref) == GIT_REF_OID) {
		git_oid oid;
		gitError = git_oid_mkstr(&oid, [newTarget UTF8String]);
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorForMkStr:gitError];
			return NO;
		}
		
		gitError = git_reference_set_oid(self.ref, &oid);
	}
	else {
		gitError = git_reference_set_target(self.ref, [newTarget UTF8String]);
	}

	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForSetRefTarget:gitError];
		return NO;
	}
	return YES;
}

- (BOOL)packAllWithError:(NSError **)error {
	
	int gitError = git_reference_packall(self.repository.repo);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForPackAllRefs:gitError];
		return NO;
	}
	return YES;
}

- (BOOL)deleteWithError:(NSError **)error {
	
	int gitError = git_reference_delete(self.ref);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForDeleteRef:gitError];
		return NO;
	}
	self.ref = NULL; /* this has been free'd */
	return YES;
}

- (GTReference *)resolvedReferenceWithError:(NSError **)error {
	
	return [GTReference referenceByResolvingSymbolicReference:self error:error];
}

@end
