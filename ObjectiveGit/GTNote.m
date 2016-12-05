//
//  GTNote.m
//  ObjectiveGitFramework
//
//  Created by Slava Karpenko on 16.05.16.
//  Copyright © 2016 Wildbit LLC. All rights reserved.
//

#import "GTNote.h"
#import "NSError+Git.h"
#import "GTSignature.h"
#import "GTReference.h"
#import "GTRepository.h"
#import "NSString+Git.h"
#import "GTOID.h"

#import "git2/errors.h"
#import "git2/notes.h"

@interface GTNote ()
{
	git_note *_note;
}

@end
@implementation GTNote

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>", NSStringFromClass([self class]), self];
}

#pragma mark API

- (void)dealloc {
	if (_note != NULL) {
		git_note_free(_note);
	}
}

- (git_note *)git_note {
	return _note;
}

- (NSString *)note {
	return @(git_note_message(self.git_note));
}

- (GTSignature *)author {
	return [[GTSignature alloc] initWithGitSignature:git_note_author(self.git_note)];
}

- (GTSignature *)committer {
	return [[GTSignature alloc] initWithGitSignature:git_note_committer(self.git_note)];
}

- (GTOID *)targetOID {
	return [GTOID oidWithGitOid:git_note_id(self.git_note)];
}

- (instancetype)initWithTargetOID:(GTOID *)oid repository:(GTRepository *)repository referenceName:(NSString *)referenceName error:(NSError **)error {
	return [self initWithTargetGitOID:(git_oid *)oid.git_oid repository:repository.git_repository referenceName:referenceName.UTF8String error:error];
}

- (instancetype)initWithTargetGitOID:(git_oid *)oid repository:(git_repository *)repository referenceName:(const char *)referenceName error:(NSError **)error {
	self = [super init];
	if (self == nil) return nil;
	
	int gitErr = git_note_read(&_note, repository, referenceName, oid);
	
	if (gitErr != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitErr description:@"Unable to read note"];
		return nil;
	}
	
	return self;
}

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

+ (NSString *)defaultReferenceNameForRepository:(GTRepository *)repository error:(NSError **)error {
	NSString *noteRef = nil;
	
	git_buf default_ref_name = { 0 };
	int gitErr = git_note_default_ref(&default_ref_name, repository.git_repository);
	if (gitErr != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitErr description:@"Unable to get default git notes reference name"];
		return nil;
	}
	
	if (default_ref_name.ptr != NULL) {
		noteRef = @(default_ref_name.ptr);
	} else {
		if (error != NULL) *error = [NSError git_errorFor:GIT_ERROR description:@"Unable to get default git notes reference name"];
	}
	
	git_buf_free(&default_ref_name);
	
	return noteRef;
}
@end
