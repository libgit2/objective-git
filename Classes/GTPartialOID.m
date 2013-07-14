//
//  GTPartialOID.m
//  ObjectiveGitFramework
//
//  Created by Sven Weidauer on 14.07.13.
//  Copyright (c) 2013 Sven Weidauer. All rights reserved.
//

#import "GTPartialOID.h"
#import "GTOID+Private.h"

@implementation GTPartialOID

- (id)initWithGitOid:(const git_oid *)git_oid length:(size_t)length {
	NSParameterAssert(0 < length && length <= GIT_OID_HEXSZ);

	self = [super initWithGitOid:git_oid];
	if (!self) return nil;

	_length = length;

	return self;
}

- (id)initWithSHACString:(const char *)string length: (size_t)length error:(NSError **)error {
	NSParameterAssert(0 < length && length <= GIT_OID_HEXSZ);
	NSParameterAssert(string != NULL);
	
	git_oid oid;
	int gitError = git_oid_fromstrn(&oid, string, length);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:[NSString stringWithFormat:@"Failed to convert string '%.*s' to partial object id", (int)length, string]];
		return nil;
	}

	return [self initWithGitOid:&oid length:length];
}

- (id)initWithSHACString:(const char *)string error:(NSError **)error {
	return [self initWithSHACString:string length:strlen(string) error:error];
}

- (id)initWithGitOid:(const git_oid *)git_oid {
	return [self initWithGitOid:git_oid length:GIT_OID_HEXSZ];
}

#pragma mark NSObject

- (BOOL)isEqual:(GTPartialOID *)object {
	if (self == object) return YES;
	if (![object isKindOfClass: self.class]) return NO;
	return self.length == object.length && git_oid_equal(self.git_oid, object.git_oid);
}

- (NSUInteger)hash {
	return (super.hash * 33) ^ self.length;
}

#pragma mark Lookup

- (int)lookupObject:(git_object **)object repository:(git_repository *)repo type:(git_otype)type {
	return git_object_lookup_prefix(object, repo, self.git_oid, self.length, type);
}

@end
