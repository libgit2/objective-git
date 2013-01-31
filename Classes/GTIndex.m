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
  return [NSString stringWithFormat:@"<%@: %p> fileURL: %@, entryCount: %lu", NSStringFromClass([self class]), self, self.fileURL, (unsigned long)self.entryCount];
}


#pragma mark API

@synthesize git_index;
@synthesize fileURL;

+ (id)indexWithFileURL:(NSURL *)localFileUrl error:(NSError **)error {	
	return [[self alloc] initWithFileURL:localFileUrl error:error];
}

+ (id)indexWithGitIndex:(git_index *)theIndex {
	return [[self alloc] initWithGitIndex:theIndex];
}

- (id)initWithFileURL:(NSURL *)localFileUrl error:(NSError **)error {
	if((self = [super init])) {
		self.fileURL = localFileUrl;
		git_index *i;
		int gitError = git_index_open(&i, [[self.fileURL path] UTF8String]);
		if(gitError < GIT_OK) {
			if(error != NULL)
				*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to initialize index."];
			return nil;
		}
		self.git_index = i;
	}
	return self;
}

- (id)initWithGitIndex:(git_index *)theIndex; {
	if((self = [super init])) {
		self.git_index = theIndex;
	}
	return self;
}

- (NSUInteger)entryCount {
	return git_index_entrycount(self.git_index);
}

- (BOOL)refreshWithError:(NSError **)error {
	int gitError = git_index_read(self.git_index);
	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to refresh index."];
		return NO;
	}
	return YES;
}

- (void)clear {
	git_index_clear(self.git_index);
}

- (GTIndexEntry *)entryAtIndex:(NSUInteger)theIndex {
	return [GTIndexEntry indexEntryWithEntry:git_index_get_byindex(self.git_index, (unsigned int)theIndex)];
}

- (GTIndexEntry *)entryWithName:(NSString *)name {
	int i = git_index_find(0, self.git_index, [name UTF8String]);
	return [GTIndexEntry indexEntryWithEntry:git_index_get_byindex(self.git_index, (unsigned int)i)];
}

- (BOOL)addEntry:(GTIndexEntry *)entry error:(NSError **)error {
	int gitError = git_index_add(self.git_index, entry.git_index_entry);
	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to add entry to index."];
		return NO;
	}
	return YES;
}

- (BOOL)addFile:(NSString *)file error:(NSError **)error {
	int gitError = git_index_add_bypath(self.git_index, file.UTF8String);
	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to add entry to index."];
		return NO;
	}
	return YES;
}

- (BOOL)writeWithError:(NSError **)error {
	int gitError = git_index_write(self.git_index);
	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to write index."];
		return NO;
	}
	return YES;
}

- (NSArray *)entries {
	NSMutableArray *entries = [NSMutableArray arrayWithCapacity:self.entryCount];
	for(NSUInteger i = 0; i < self.entryCount; i++) {
		[entries addObject:[self entryAtIndex:i]];
	}
	
	return [entries copy];
}

@end
