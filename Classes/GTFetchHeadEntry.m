//
//  GTFetchHeadEntry.m
//  ObjectiveGitFramework
//
//  Created by Pablo Bendersky on 8/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFetchHeadEntry.h"

@implementation GTFetchHeadEntry

- (instancetype)initWithReference:(GTReference *)reference remoteURL:(NSString *)remoteURL targetOID:(GTOID *)targetOID isMerge:(BOOL)merge {
	self = [super init];
	if (self == nil) return nil;

	_reference = reference;
	_remoteURL = [remoteURL copy];
	_targetOID = targetOID;
	_merge = merge;

	return self;
}

+ (instancetype)fetchEntryWithReference:(GTReference *)reference remoteURL:(NSString *)remoteURL targetOID:(GTOID *)targetOID isMerge:(BOOL)merge {
	return [[self alloc] initWithReference:reference remoteURL:remoteURL targetOID:targetOID isMerge:merge];
	
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ reference: %@, remoteURL: %@, targetOID: %@, merge: %i }",
			self.class, self, self.reference, self.remoteURL, self.targetOID, (int)_merge];
}

@end
