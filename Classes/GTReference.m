//
//  GTReference.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/2/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTReference.h"
#import "GTRepository.h"
#import "GTLib.h"
#import "NSString+Git.h"
#import "NSError+Git.h"


@implementation GTReference

@synthesize ref;
@synthesize repo;
@synthesize name;
@synthesize type;

+ (id)referenceByLookingUpRef:(NSString *)refName inRepo:(GTRepository *)theRepo error:(NSError **)error {

	return [[[GTReference alloc] initByLookingUpRef:refName inRepo:theRepo error:error] autorelease];
}

+ (id)referenceByCreatingRef:(NSString *)refName fromRef:(NSString *)target inRepo:(GTRepository *)theRepo error:(NSError **)error {
		
	return [[[GTReference alloc] initByCreatingRef:refName fromRef:target inRepo:theRepo error:error] autorelease];
}

- (id)initByLookingUpRef:(NSString *)refName inRepo:(GTRepository *)theRepo error:(NSError **)error {
	
	if(self = [super init]) {
		self.repo = theRepo;
		int gitError = git_reference_lookup(&ref, self.repo.repo, [NSString utf8StringForString:refName]);
		if(gitError != GIT_SUCCESS){
			if(error != NULL)
				*error = [NSError gitErrorForLookupRef:gitError];
			return nil;
		}
	}
	return self;
}

- (id)initByCreatingRef:(NSString *)refName fromRef:(NSString *)theTarget inRepo:(GTRepository *)theRepo error:(NSError **)error {
	
	if(self = [super init]) {
		
		git_oid oid;
		int gitError;
		
		self.repo = theRepo;
		if (git_oid_mkstr(&oid, [NSString utf8StringForString:theTarget]) == GIT_SUCCESS) {
			
			gitError = git_reference_create_oid(&ref, 
												self.repo.repo, 
												[NSString utf8StringForString:refName], 
												&oid);
		}
		else {
			
			gitError = git_reference_create_symbolic(&ref, 
													 self.repo.repo, 
													 [NSString utf8StringForString:refName], 
													 [NSString utf8StringForString:theTarget]);
		}
		
		if(gitError != GIT_SUCCESS){
			if(error != NULL)
				*error = [NSError gitErrorForCreateRef:gitError];
			return nil;
		}
	}
	return self;
}

- (NSString *)name {
	
	return [NSString stringForUTF8String:git_reference_name(self.ref)];
}
- (void)setName:(NSString *)newName {
	
	// todo: this can return an error
	// should we use NSError ?
	git_reference_rename(self.ref, [NSString utf8StringForString:newName]);
}

- (NSString *)type {
	
	return [NSString stringForUTF8String:git_object_type2string(git_reference_type(self.ref))];
}

- (NSString *)target {
	
	if(git_reference_type(self.ref) == GIT_REF_OID) {
		
		return [GTLib hexFromOid:git_reference_oid(self.ref)];
	}
	else {
		return [NSString stringForUTF8String:git_reference_target(self.ref)];
	}
}
- (void)setTarget:(NSString *)newTarget error:(NSError **)error {
	
	int gitError;
	
	if(git_reference_type(self.ref) == GIT_REF_OID) {
		
		git_oid oid;
		gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:newTarget]);
		if(gitError != GIT_SUCCESS){
			if(error != NULL)
				*error = [NSError gitErrorForMkStr:gitError];
			return;
		}
		
		gitError = git_reference_set_oid(self.ref, &oid);
	}
	else {
		
		gitError = git_reference_set_target(self.ref, [NSString utf8StringForString:newTarget]);
	}

	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForSetRefTarget:gitError];
		return;
	}
}

- (void)packAllAndReturnError:(NSError **)error {
	
	int gitError = git_reference_packall(self.repo.repo);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForPackAllRefs:gitError];
		return;
	}
}

- (void)deleteAndReturnError:(NSError **)error {
	
	int gitError = git_reference_delete(self.ref);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForDeleteRef:gitError];
		return;
	}
	self.ref = NULL; /* this has been free'd */
}

- (void)dealloc {
	
	self.repo = nil;
	// All these properties pass through to underlying C object
	// there is nothing to release here
	//self.name = nil;
	//self.type = nil;
	[super dealloc];
}

@end
