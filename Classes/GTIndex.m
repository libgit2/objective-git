//
//  GTIndex.m
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

#import "GTIndex.h"
#import "GTIndexEntry.h"
#import "NSError+Git.h"

@implementation GTIndex

#pragma mark NSObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> fileURL: %@, entryCount: %lu", NSStringFromClass([self class]), self, self.fileURL, (unsigned long)self.entryCount];
}

#pragma mark Lifecycle

- (void)dealloc {
	if (_git_index != NULL) git_index_free(_git_index);
}

- (id)initWithFileURL:(NSURL *)fileURL error:(NSError **)error {
	NSParameterAssert(fileURL != nil);

	self = [super init];
	if (self == nil) return nil;

	git_index *index = NULL;
	int status = git_index_open(&index, fileURL.path.fileSystemRepresentation);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to initialize index."];
		return nil;
	}

	_fileURL = [fileURL copy];
	_git_index = index;

	return self;
}

- (id)initWithGitIndex:(git_index *)index repository:(GTRepository *)repository {
	NSParameterAssert(index != NULL);
	NSParameterAssert(repository != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_index = index;
	_repository = repository;

	return self;
}

#pragma mark Entries

- (NSUInteger)entryCount {
	return git_index_entrycount(self.git_index);
}

- (BOOL)refresh:(NSError **)error {
	int status = git_index_read(self.git_index);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to refresh index."];
		return NO;
	}
	
	return YES;
}

- (void)clear {
	git_index_clear(self.git_index);
}

- (GTIndexEntry *)entryAtIndex:(NSUInteger)index {
	const git_index_entry *entry = git_index_get_byindex(self.git_index, (unsigned int)index);
	if (entry == NULL) return nil;
	
	return [[GTIndexEntry alloc] initWithGitIndexEntry:entry];
}

- (GTIndexEntry *)entryWithName:(NSString *)name {
	int index = git_index_find(0, self.git_index, name.UTF8String);
	const git_index_entry *entry = git_index_get_byindex(self.git_index, (unsigned int)index);
	if (entry == NULL) return nil;

	return [[GTIndexEntry alloc] initWithGitIndexEntry:entry];
}

- (BOOL)addEntry:(GTIndexEntry *)entry error:(NSError **)error {
	int status = git_index_add(self.git_index, entry.git_index_entry);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to add entry to index."];
		return NO;
	}
	
	return YES;
}

- (BOOL)addFile:(NSString *)file error:(NSError **)error {
	int status = git_index_add_bypath(self.git_index, file.UTF8String);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to add entry to index."];
		return NO;
	}
	
	return YES;
}

- (BOOL)write:(NSError **)error {
	int status = git_index_write(self.git_index);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to write index."];
		return NO;
	}
	
	return YES;
}

- (NSArray *)entries {
	NSMutableArray *entries = [NSMutableArray arrayWithCapacity:self.entryCount];
	for (NSUInteger i = 0; i < self.entryCount; i++) {
		[entries addObject:[self entryAtIndex:i]];
	}
	
	return entries;
}

@end
