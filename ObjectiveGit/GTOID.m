//
//  GTOID.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTOID.h"
#import "NSError+Git.h"

#import "git2/errors.h"
#import "git2/odb.h"

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
	char *SHA = git_oid_tostr_s(self.git_oid);
	NSString *str = [[NSString alloc] initWithBytes:SHA
                                             length:GIT_OID_HEXSZ
                                           encoding:NSUTF8StringEncoding];
	NSAssert(str != nil, @"Failed to create SHA string");
	return str;
}

#pragma mark Lifecycle

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

- (instancetype)initWithGitOid:(const git_oid *)oid {
	NSParameterAssert(oid != NULL);

	self = [super init];
	if (self == nil) return nil;

	git_oid_cpy(&_git_oid, oid);

	return self;
}

- (instancetype)initWithSHA:(NSString *)SHA error:(NSError **)error {
	NSParameterAssert(SHA != nil);
	return [self initWithSHACString:SHA.UTF8String error:error];
}

- (instancetype)initWithSHA:(NSString *)SHA {
	return [self initWithSHA:SHA error:NULL];
}

- (instancetype)initWithSHACString:(const char *)string error:(NSError **)error {
	NSParameterAssert(string != NULL);
	
	self = [super init];
	if (self == nil) return nil;
	
	int status = git_oid_fromstr(&_git_oid, string);
	if (status != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:status description:@"Failed to convert string '%s' to object id", string];
		}
		return nil;
	}

	return self;
}

- (instancetype)initWithSHACString:(const char *)string {
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

- (BOOL)isZero {
	return git_oid_iszero(self.git_oid) != 0;
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

@end

@implementation GTOID (GTObjectDatabase)

+ (instancetype)OIDByHashingData:(NSData *)data type:(GTObjectType)type error:(NSError **)error {
	NSParameterAssert(data != nil);

	git_oid oid;
	int gitError = git_odb_hash(&oid, data.bytes, data.length, (git_otype)type);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to hash"];
		return nil;
	}
	
	return [[self alloc] initWithGitOid:&oid];
}

@end
