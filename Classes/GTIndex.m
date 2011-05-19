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

- (void)dealloc {
	
	//git_index_free(self.index);
	self.path = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark API

@synthesize index;
@synthesize path;
@synthesize entryCount;

- (id)initWithPath:(NSURL *)localFileUrl error:(NSError **)error {
	
	if((self = [super init])) {
		self.path = localFileUrl;
		git_index *i;
		int gitError = git_index_open_bare(&i, [[self.path path] UTF8String]);
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorForInitIndex:gitError];
            [self release];
			return nil;
		}
		self.index = i;
	}
	return self;
}
+ (id)indexWithPath:(NSURL *)localFileUrl error:(NSError **)error {
	
	return [[[self alloc] initWithPath:localFileUrl error:error] autorelease];
}

- (id)initWithGitIndex:(git_index *)theIndex; {
	
	if((self = [super init])) {
		self.index = theIndex;
	}
	return self;
}
+ (id)indexWithGitIndex:(git_index *)theIndex {
	
	return [[[self alloc] initWithGitIndex:theIndex] autorelease];
}

- (NSInteger)entryCount {
	
	return git_index_entrycount(self.index);
}

- (BOOL)refreshWithError:(NSError **)error {
	
	int gitError = git_index_read(self.index);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForReadIndex:gitError];
		return NO;
	}
	return YES;
}

- (void)clear {
	
	git_index_clear(self.index);
}

- (GTIndexEntry *)entryAtIndex:(NSInteger)theIndex {
	
	return [GTIndexEntry indexEntryWithEntry:git_index_get(self.index, theIndex)];
}

- (GTIndexEntry *)entryWithName:(NSString *)name {
	
	int i = git_index_find(self.index, [name UTF8String]);
	return [GTIndexEntry indexEntryWithEntry:git_index_get(self.index, i)];
}

- (BOOL)addEntry:(GTIndexEntry *)entry error:(NSError **)error {
	
	int gitError = git_index_add2(self.index, entry.entry);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForAddEntryToIndex:gitError];
		return NO;
	}
	return YES;
}

- (BOOL)addFile:(NSString *)file error:(NSError **)error {
	
	int gitError = git_index_add(self.index, [file UTF8String], 0);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForAddEntryToIndex:gitError];
		return NO;
	}
	return YES;
}

- (BOOL)writeWithError:(NSError **)error {
	
	int gitError = git_index_write(self.index);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForWriteIndex:gitError];
		return NO;
	}
	return YES;
}

@end
