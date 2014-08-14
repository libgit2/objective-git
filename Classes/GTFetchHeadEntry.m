//
//  GTFetchHeadEntry.m
//  ObjectiveGitFramework
//
//  Created by Pablo Bendersky on 8/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFetchHeadEntry.h"

@implementation GTFetchHeadEntry

- (instancetype)initWithRepository:(GTRepository *)repository reference:(GTReference *)reference remoteURL:(NSString *)remoteURL targetOID:(GTOID *)targetOID isMerge:(BOOL)merge {
	self = [super init];
	if (self) {
		_repository = repository;
		_reference = reference;
		_remoteURL = [remoteURL copy];
		_targetOID = targetOID;
		_merge = merge;
	}
	return self;
}

+ (instancetype)fetchEntryWithRepository:(GTRepository *)repository reference:(GTReference *)reference remoteURL:(NSString *)remoteURL targetOID:(GTOID *)targetOID isMerge:(BOOL)merge {
	return [[self alloc] initWithRepository:repository
								  reference:reference
								  remoteURL:remoteURL
								  targetOID:targetOID
									isMerge:merge];
	
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ repository: %@, reference: %@, remoteURL: %@, targetOID: %@, merge: %i }",
			self.class, self, self.repository, self.reference, self.remoteURL, self.targetOID, (int)_merge];
}

@end
