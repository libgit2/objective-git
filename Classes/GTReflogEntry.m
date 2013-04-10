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

@end

@implementation GTReflogEntry

#pragma mark Lifecycle

- (id)initWithGitReflogEntry:(const git_reflog_entry *)entry {
	NSParameterAssert(entry != NULL);

	self = [super init];
	if (self == nil) return nil;

	_git_reflog_entry = entry;

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
	return @(git_reflog_entry_message(self.git_reflog_entry));
}

@end
