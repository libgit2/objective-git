//
//  GTOID.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTOID.h"

@implementation GTOID

#pragma mark Lifecycle

- (void)dealloc {
	free(_git_oid);
}

- (id)initWithGitOid:(const git_oid *)oid {
	NSParameterAssert(oid != NULL);

	self = [super init];
	if (self == nil) return nil;

	_git_oid = malloc(sizeof(git_oid));
	git_oid_cpy(_git_oid, oid);

	return self;
}

- (id)initWithSHA:(NSString *)SHA {
	git_oid *oid = malloc(sizeof(git_oid));
	int status = git_oid_fromstr(oid, SHA.UTF8String);
	if (status != GIT_OK) return nil;

	GTOID *OID = [self initWithGitOid:oid];
	free(oid);
	return OID;
}

#pragma mark NSObject

- (NSUInteger)hash {
	return self.SHA.hash;
}

- (BOOL)isEqual:(GTOID *)object {
	if (object == self) return YES;
	if (![object isKindOfClass:GTOID.class]) return NO;

	return (BOOL)git_oid_equal(self.git_oid, object.git_oid);
}

#pragma mark SHA

- (NSString *)SHA {
	char SHA[41];
	git_oid_fmt(SHA, self.git_oid);
	SHA[40] = 0;
	return @(SHA);
}

@end
