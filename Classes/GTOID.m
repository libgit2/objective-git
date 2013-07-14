//
//  GTOID.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTOID.h"
#import "GTOID+Private.h"

#import "NSError+Git.h"
#import "GTObject.h"
#import "GTRepository.h"

@interface GTOID () {
	git_oid _git_oid;
}

@end

@implementation GTOID

#pragma mark Properties

- (const git_oid *)git_oid {
	return &_git_oid;
}

- (NSString *)SHA {
	char *SHA = malloc(GIT_OID_HEXSZ);
	if (SHA == NULL) return nil;

	git_oid_fmt(SHA, self.git_oid);

	NSString *str = [[NSString alloc] initWithBytesNoCopy:SHA length:GIT_OID_HEXSZ encoding:NSUTF8StringEncoding freeWhenDone:YES];
	if (str == nil) free(SHA);
	return str;
}

#pragma mark Lifecycle

- (id)initWithGitOid:(const git_oid *)oid {
	NSParameterAssert(oid != NULL);

	self = [super init];
	if (self == nil) return nil;

	git_oid_cpy(&_git_oid, oid);

	return self;
}

- (id)initWithSHA:(NSString *)SHA error:(NSError **)error {
	NSParameterAssert(SHA != nil);
	return [self initWithSHACString:SHA.UTF8String error:error];
}

- (id)initWithSHA:(NSString *)SHA {
	return [self initWithSHA:SHA error:NULL];
}

- (id)initWithSHACString:(const char *)string error:(NSError **)error {
	NSParameterAssert(string != NULL);
	
	self = [super init];
	if (self == nil) return nil;
	
	int status = git_oid_fromstr(&_git_oid, string);
	if (status != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:status withAdditionalDescription:[NSString stringWithFormat:@"Failed to convert string '%s' to object id", string]];
		}
		return nil;
	}

	return self;
}

- (id)initWithSHACString:(const char *)string {
	return [self initWithSHACString:string error:NULL];
}

+ (instancetype)oidWithGitOid:(const git_oid *)git_oid {
	return [[self alloc] initWithGitOid:git_oid];
}

+ (instancetype)oidWithSHA:(NSString *)SHA {
	return [[self alloc] initWithSHA:SHA];
}

+ (instancetype)oidWithSHACString:(const char *)SHA {
	return [[self alloc] initWithSHACString:SHA];
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ SHA: %@ }", self.class, self, self.SHA];
}

- (NSUInteger)hash {
	// Hash the raw OID.
	NSData *data = [[NSData alloc] initWithBytesNoCopy:_git_oid.id length:GIT_OID_RAWSZ freeWhenDone:NO];
	return data.hash;
}

- (BOOL)isEqual:(GTOID *)object {
	if (object == self) return YES;
	if (![object isKindOfClass:GTOID.class]) return NO;

	return (BOOL)git_oid_equal(self.git_oid, object.git_oid);
}

- (id)copyWithZone:(NSZone *)zone {
	// Optimization: Since this class is immutable we don't need to create an actual copy.
	return self;
}

#pragma mark Lookup

- (GTObject *)lookupObjectInRepository: (GTRepository *)repo type: (GTObjectType)type error: (NSError **)error {
	git_object *obj;

	int gitError = [self lookupObject:&obj repository:repo.git_repository type:(git_otype)type];
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to lookup object in repository."];
		return nil;
	}

    return [GTObject objectWithObj:obj inRepository:repo];
}

- (int)lookupObject:(git_object **)object repository:(git_repository *)repo type:(git_otype)type {
	return git_object_lookup(object, repo, self.git_oid, type);
}

- (int)readObject:(git_odb_object **)object database:(git_odb *)db {
	return git_odb_read(object, db, self.git_oid);
}

- (BOOL)isFullOID {
	return YES;
}

- (GTOID *)completeOIDInRepository:(GTRepository *)repository error:(NSError **)error {
	if (self.isFullOID) return self;
	GTObject *object = [self lookupObjectInRepository:repository type:GTObjectTypeAny error:error];
	if (object == nil) return nil;
	return object.OID;
}

@end
