//
//  GTOID.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTOID.h"

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

- (id)initWithSHA:(NSString *)SHA {
	NSParameterAssert(SHA != nil);

	self = [super init];
	if (self == nil) return nil;

	int status = git_oid_fromstr(&_git_oid, SHA.UTF8String);
	if (status != GIT_OK) return nil;

	return self;
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

@end
