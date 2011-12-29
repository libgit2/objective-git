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

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> path: %@, entryCount: %i", NSStringFromClass([self class]), self, self.path, self.entryCount];
}


#pragma mark API

@synthesize index;
@synthesize path;
@synthesize entryCount;

+ (id)indexWithPath:(NSURL *)localFileUrl error:(NSError **)error {	
	return [[self alloc] initWithPath:localFileUrl error:error];
}

+ (id)indexWithGitIndex:(git_index *)theIndex {
	return [[self alloc] initWithGitIndex:theIndex];
}

- (id)initWithPath:(NSURL *)localFileUrl error:(NSError **)error {
	if((self = [super init])) {
		self.path = localFileUrl;
		git_index *i;
		int gitError = git_index_open(&i, [[self.path path] UTF8String]);
		if(gitError < GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError git_errorFor:gitError withDescription:@"Failed to initialize index."];
			return nil;
		}
		self.index = i;
	}
	return self;
}

- (id)initWithGitIndex:(git_index *)theIndex; {
	if((self = [super init])) {
		self.index = theIndex;
	}
	return self;
}

- (NSInteger)entryCount {
	return git_index_entrycount(self.index);
}

- (BOOL)refreshWithError:(NSError **)error {
	int gitError = git_index_read(self.index);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withDescription:@"Failed to refresh index."];
		return NO;
	}
	return YES;
}

- (void)clear {
	git_index_clear(self.index);
}

- (GTIndexEntry *)entryAtIndex:(NSInteger)theIndex {
	return [GTIndexEntry indexEntryWithEntry:git_index_get(self.index, (unsigned int)theIndex)];
}

- (GTIndexEntry *)entryWithName:(NSString *)name {
	int i = git_index_find(self.index, [name UTF8String]);
	return [GTIndexEntry indexEntryWithEntry:git_index_get(self.index, (unsigned int) i)];
}

- (BOOL)addEntry:(GTIndexEntry *)entry error:(NSError **)error {
	int gitError = git_index_add2(self.index, entry.entry);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorForAddEntryToIndex:gitError];
		return NO;
	}
	return YES;
}

- (BOOL)addFile:(NSString *)file error:(NSError **)error {
	int gitError = git_index_add(self.index, [file UTF8String], 0);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorForAddEntryToIndex:gitError];
		return NO;
	}
	return YES;
}

- (BOOL)writeWithError:(NSError **)error {
	int gitError = git_index_write(self.index);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withDescription:@"Failed to write index."];
		return NO;
	}
	return YES;
}

@end
