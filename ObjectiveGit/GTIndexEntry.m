//
//  GTIndexEntry.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "GTIndexEntry.h"
#import "NSError+Git.h"
#import "NSString+Git.h"
#import "GTOID.h"
#import "GTRepository.h"
#import "GTIndex.h"

#import "git2.h"

@interface GTIndexEntry ()
@property (nonatomic, assign, readonly) const git_index_entry *git_index_entry;
@end

@implementation GTIndexEntry

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> path: %@", self.class, self, self.path];
}

#pragma mark Lifecycle

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

- (instancetype)initWithGitIndexEntry:(const git_index_entry *)entry index:(GTIndex *)index error:(NSError **)error {
	NSParameterAssert(entry != NULL);

	self = [super init];
	if (self == nil) return nil;

	_git_index_entry = entry;
	_index = index;

	return self;
}

- (instancetype)initWithGitIndexEntry:(const git_index_entry *)entry {
	return [self initWithGitIndexEntry:entry index:nil error:NULL];
}

#pragma mark Properties

- (NSString *)path {
	return @(self.git_index_entry->path);
}

- (int)flags {
	return (self.git_index_entry->flags & 0xFFFF) | (self.git_index_entry->flags_extended << 16);
}

- (BOOL)isStaged {
	return (self.git_index_entry->flags & GIT_IDXENTRY_STAGEMASK) >> GIT_IDXENTRY_STAGESHIFT;
}

- (GTIndexEntryStatus)status {
	if ((self.flags & (GIT_IDXENTRY_UPDATE << 16)) != 0) {
		return GTIndexEntryStatusUpdated;
	} else if ((self.flags & (GIT_IDXENTRY_UPTODATE << 16)) != 0) {
		return GTIndexEntryStatusUpToDate;
	} else if ((self.flags & (GIT_IDXENTRY_CONFLICTED << 16)) != 0) {
		return GTIndexEntryStatusConflicted;
	} else if ((self.flags & (GIT_IDXENTRY_ADDED << 16)) != 0) {
		return GTIndexEntryStatusAdded;
	} else if ((self.flags & (GIT_IDXENTRY_REMOVE << 16)) != 0) {
		return GTIndexEntryStatusRemoved;
	}

	return GTIndexEntryStatusUpToDate;
}

- (GTOID *)OID {
	return [GTOID oidWithGitOid:&self.git_index_entry->id];
}

#pragma mark API

- (GTRepository *)repository {
	return self.index.repository;
}

- (GTObject *)GTObject:(NSError **)error {
	return [GTObject objectWithIndexEntry:self error:error];
}

@end

@implementation GTObject (GTIndexEntry)

+ (instancetype)objectWithIndexEntry:(GTIndexEntry *)indexEntry error:(NSError **)error {
	return [[self alloc] initWithIndexEntry:indexEntry error:error];
}

- (instancetype)initWithIndexEntry:(GTIndexEntry *)indexEntry error:(NSError **)error {
	git_object *obj;
	int gitError = git_object_lookup(&obj, indexEntry.repository.git_repository, indexEntry.OID.git_oid, (git_otype)GTObjectTypeAny);

	if (gitError < GIT_OK) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to get object for index entry."];
		}

		return nil;
	}

	return [self initWithObj:obj inRepository:indexEntry.repository];
}

@end
