//
//  GTTemporaryReference.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 16/07/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTTemporaryReference.h"

@interface GTTemporaryReference () {
	GTOID *_OID;
}
@end

@implementation GTTemporaryReference

+ (id)temporaryReferenceToOID:(GTOID *)oid {
	return [[self alloc] initWithOID:oid];
}

- (id)initWithOID:(GTOID *)oid {
	NSParameterAssert(oid != nil);

	self = [super init];
	if (self == nil) return nil;

	_OID = oid;

	return self;
}

- (git_reference *)git_reference {
	return NULL;
}

- (const git_oid *)git_oid {
	return self.OID.git_oid;
}

- (GTReferenceType)referenceType {
	return GTReferenceTypeInvalid;
}

- (id)unresolvedTarget {
	return self.resolvedTarget;
}

- (id)resolvedTarget {
	return [self.repository lookupObjectByOID:self.OID error:NULL];
}

- (GTReference *)resolvedReference {
	return nil;
}

- (GTReflog *)reflog {
	return nil;
}

- (GTReference *)referenceByRenaming:(NSString *)newName error:(NSError **)error {
    NSAssert(NO, @"Temporary references can't be renamed");
	return nil;
}

- (GTReference *)referenceByUpdatingTarget:(NSString *)newTarget error:(NSError **)error {
	NSAssert(NO, @"Temporary references can't be updated");
	return nil;
}

- (BOOL)deleteWithError:(NSError **)error {
	return YES;
}

- (GTReference *)resolvedReferenceWithError:(NSError **)error {
	NSAssert(NO, @"Temporary references can't be resolved");
	return nil;
}

- (GTReference *)reloadedReferenceWithError:(NSError **)error {
	NSAssert(NO, @"Temporary references can't be reloaded");
	return nil;
}

#pragma mark NSObject

- (NSUInteger)hash {
	return self.OID.hash;
}

- (BOOL)isEqual:(GTReference *)reference {
	if (self == reference) return YES;
	if (![reference isKindOfClass:GTReference.class]) return NO;
	
	return [self.unresolvedTarget isEqual:reference.unresolvedTarget];
}


@end
