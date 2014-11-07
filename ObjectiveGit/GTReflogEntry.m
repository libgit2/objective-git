//
//  GTReflogEntry.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTReflogEntry.h"
#import "GTReflog+Private.h"
#import "GTOID.h"
#import "GTSignature.h"

@interface GTReflogEntry ()

@property (nonatomic, readonly, assign) const git_reflog_entry *git_reflog_entry;

// The reflog isn't actually used for anything directly, but we want to keep it
// alive as long as the entry is alive.
@property (nonatomic, readonly, strong) GTReflog *reflog;

@end

@implementation GTReflogEntry

#pragma mark Lifecycle

- (id)initWithGitReflogEntry:(const git_reflog_entry *)entry reflog:(GTReflog *)reflog {
	NSParameterAssert(entry != NULL);
	NSParameterAssert(reflog != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_reflog_entry = entry;
	_reflog = reflog;

	return self;
}

#pragma mark Properties

- (GTOID *)previousOID {
	return [[GTOID alloc] initWithGitOid:git_reflog_entry_id_old(self.git_reflog_entry)];
}

- (GTOID *)updatedOID {
	return [[GTOID alloc] initWithGitOid:git_reflog_entry_id_new(self.git_reflog_entry)];
}

- (GTSignature *)committer {
	return [[GTSignature alloc] initWithGitSignature:git_reflog_entry_committer(self.git_reflog_entry)];
}

- (NSString *)message {
	const char *message = git_reflog_entry_message(self.git_reflog_entry);
	if (message == NULL) return nil;

	return @(message);
}

@end
