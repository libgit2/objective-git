//
//  GTTemporaryReference.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 16/07/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTTemporaryReference.h"

@interface GTTemporaryReference () {
	GTOID *_oid;
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

	_oid = oid;

	return self;
}
@end
