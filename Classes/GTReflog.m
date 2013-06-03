//
//  GTReflog.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTReflog.h"
#import "GTReflog+Private.h"
#import "GTSignature.h"
#import "GTReference.h"
#import "NSError+Git.h"
#import "GTReflogEntry+Private.h"

@interface GTReflog ()

@property (nonatomic, assign) git_reflog *git_reflog;

@property (nonatomic, readonly, weak) GTReference *reference;

@end

@implementation GTReflog

#pragma mark Lifecycle

- (void)dealloc {
	if (_git_reflog != NULL) git_reflog_free(_git_reflog);
}

- (id)initWithReference:(GTReference *)reference {
	NSParameterAssert(reference != nil);

	self = [super init];
	if (self == nil) return nil;

	_reference = reference;
	BOOL success = [self reload:NULL];
	if (!success) return nil;

	return self;
}

#pragma mark Entries

- (BOOL)writeEntryWithCommitter:(GTSignature *)committer message:(NSString *)message error:(NSError **)error {
	NSParameterAssert(committer != nil);

	// Make sure the reference and reflog are as up-to-date as possible before
	// we try to write.
	BOOL success = [self reload:error];
	if (!success) return NO;

	int status = git_reflog_append(self.git_reflog, self.reference.git_oid, committer.git_signature, message.UTF8String);
	if (status != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:status withAdditionalDescription:@"Could not append to reflog"];
		}
		return NO;
	}

	status = git_reflog_write(self.git_reflog);
	if (status != GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:status withAdditionalDescription:@"Could not write reflog"];
		}
		return NO;
	}

	return YES;
}

- (GTReflogEntry *)entryAtIndex:(NSUInteger)index {
	NSParameterAssert(index < self.entryCount);

	const git_reflog_entry *entry = git_reflog_entry_byindex(self.git_reflog, index);
	if (entry == NULL) return nil;

	return [[GTReflogEntry alloc] initWithGitReflogEntry:entry];
}

- (NSUInteger)entryCount {
	return git_reflog_entrycount(self.git_reflog);
}

#pragma mark Reloading

- (BOOL)reload:(NSError **)error {
	BOOL success = [self.reference reloadWithError:error];
	if (!success) return NO;

	git_reflog *reflog = NULL;
	int status = git_reflog_read(&reflog, self.reference.git_reference);
	if (status != GIT_OK || reflog == NULL) {
		if (reflog != NULL) git_reflog_free(reflog);
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:[NSString stringWithFormat:@"Couldn't read reflog for reference: %@", self.reference]];
		return NO;
	}

	self.git_reflog = reflog;

	return YES;
}

- (void)setGit_reflog:(git_reflog *)git_reflog {
	if (_git_reflog != NULL) git_reflog_free(_git_reflog);
	_git_reflog = git_reflog;
}

@end
