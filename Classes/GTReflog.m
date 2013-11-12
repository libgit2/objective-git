//
//  GTReflog.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTReflog.h"
#import "GTReflog+Private.h"
#import "GTRepository.h"
#import "GTSignature.h"
#import "GTReference.h"
#import "NSError+Git.h"
#import "GTReflogEntry+Private.h"

@interface GTReflog ()

@property (nonatomic, readonly, assign) git_reflog *git_reflog;

@property (nonatomic, readonly, strong) GTReference *reference;

@end

@implementation GTReflog

#pragma mark Lifecycle

- (void)dealloc {
	if (_git_reflog != NULL) git_reflog_free(_git_reflog);
}

- (id)initWithReference:(GTReference *)reference {
	NSParameterAssert(reference != nil);
	NSParameterAssert(reference.name != nil);

	self = [super init];
	if (self == nil) return nil;

	_reference = reference;

	int status = git_reflog_read(&_git_reflog, reference.repository.git_repository, reference.name.UTF8String);
	if (status != GIT_OK || _git_reflog == NULL) return nil;

	return self;
}

#pragma mark Entries

- (BOOL)writeEntryWithCommitter:(GTSignature *)committer message:(NSString *)message error:(NSError **)error {
	NSParameterAssert(committer != nil);

	int status = git_reflog_append(self.git_reflog, self.reference.git_oid, committer.git_signature, message.UTF8String);
	if (status != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:status description:@"Could not append to reflog"];
		}
		return NO;
	}

	status = git_reflog_write(self.git_reflog);
	if (status != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:status description:@"Could not write reflog"];
		}
		return NO;
	}

	return YES;
}

- (GTReflogEntry *)entryAtIndex:(NSUInteger)index {
	NSParameterAssert(index < self.entryCount);

	const git_reflog_entry *entry = git_reflog_entry_byindex(self.git_reflog, index);
	if (entry == NULL) return nil;

	return [[GTReflogEntry alloc] initWithGitReflogEntry:entry reflog:self];
}

- (NSUInteger)entryCount {
	return git_reflog_entrycount(self.git_reflog);
}

@end
