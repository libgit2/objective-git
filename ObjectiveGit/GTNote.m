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

- (NSString*)note {
	return @(git_note_message(self.git_note));
}

- (GTSignature *)author {
	return [[GTSignature alloc] initWithGitSignature:git_note_author(self.git_note)];
}

- (GTSignature *)committer {
	return [[GTSignature alloc] initWithGitSignature:git_note_committer(self.git_note)];
}

- (GTOID*)targetOID {
	return [GTOID oidWithGitOid:git_note_id(self.git_note)];
}

- (instancetype)initWithTargetOID:(GTOID*)oid repository:(GTRepository*)repository ref:(NSString*)ref {
	return [self initWithTargetGitOID:(git_oid *)oid.git_oid repository:repository.git_repository ref:ref.UTF8String];
}

- (instancetype)initWithTargetGitOID:(git_oid*)oid repository:(git_repository *)repository ref:(const char*)ref {
	if (self = [super init]) {
		int gitErr = git_note_read(&_note, repository, ref, oid);
		
		if (gitErr != GIT_OK)
			return nil;		// Cannot read the note, means it either doesn't exists for this object, this object is not found, or whatever else.
	}
	
	return self;
}

@end
