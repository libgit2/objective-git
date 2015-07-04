//
//  GTFetchHeadEntry.m
//  ObjectiveGitFramework
//
//  Created by Pablo Bendersky on 8/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFetchHeadEntry.h"
#import "GTOID.h"
#import "GTReference.h"

@implementation GTFetchHeadEntry

// XCode 7+ require overriding super designated initializers
- (instancetype)init
{
	return [self initWithReference:[GTReference new] remoteURLString:@"" targetOID:[GTOID new] isMerge:NO];
}

- (instancetype)initWithReference:(GTReference *)reference remoteURLString:(NSString *)remoteURLString targetOID:(GTOID *)targetOID isMerge:(BOOL)merge {
	NSParameterAssert(reference != nil);
	NSParameterAssert(remoteURLString != nil);
	NSParameterAssert(targetOID != nil);
	
	self = [super init];
	if (self == nil) return nil;

	_reference = reference;
	_remoteURLString = [remoteURLString copy];
	_targetOID = [targetOID copy];
	_merge = merge;

	return self;
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ reference: %@, remoteURL: %@, targetOID: %@, merge: %i }", self.class, self, self.reference, self.remoteURLString, self.targetOID, (int)self.merge];
}

@end
