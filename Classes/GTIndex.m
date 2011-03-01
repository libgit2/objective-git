//
//  GTIndex.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTIndex.h"
#import "GTIndexEntry.h"
#import "NSString+Git.h"
#import "NSError+Git.h"

@implementation GTIndex

@synthesize index;
@synthesize path;
@synthesize entryCount;

#pragma mark -
#pragma mark Initialization

+ (id)indexWithPath:(NSURL *)localFileUrl error:(NSError **)error {
	
	return [[[GTIndex alloc] initWithPath:localFileUrl error:error] autorelease];
}

- (id)initWithPath:(NSURL *)localFileUrl error:(NSError **)error {
	
	if(self = [super init]) {
		self.path = localFileUrl;
		git_index *i;
		int gitError = git_index_open_bare(&i, [NSString utf8StringForString:[self.path path]]);
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorForInitIndex:gitError];
			return nil;
		}
		self.index = i;
	}
	return self;
}

+ (id)indexWithIndex:(git_index *)theIndex {
	
	return [[[GTIndex alloc] initWithGitIndex:theIndex] autorelease];
}

- (id)initWithGitIndex:(git_index *)theIndex; {
	
	if(self = [super init]){
		self.index = theIndex;
	}
	return self;
}

#pragma mark -
#pragma mark API

- (NSInteger)entryCount {
	
	return git_index_entrycount(self.index);
}

- (void)refreshAndReturnError:(NSError **)error {
	
	int gitError = git_index_read(self.index);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForReadIndex:gitError];
	}
}

- (void)clear {
	
	git_index_clear(self.index);
}

- (GTIndexEntry *)getEntryAtIndex:(NSInteger)theIndex {
	
	return [GTIndexEntry indexEntryWithEntry:git_index_get(self.index, theIndex)];
}

- (GTIndexEntry *)getEntryWithName:(NSString *)name {
	
	int i = git_index_find(self.index, [NSString utf8StringForString:name]);
	return [GTIndexEntry indexEntryWithEntry:git_index_get(self.index, i)];
}

- (void)addEntry:(GTIndexEntry *)entry error:(NSError **)error {

	int gitError = git_index_insert(self.index, entry.entry);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForAddEntryToIndex:gitError];
	}
}

- (void)addFile:(NSString *)file error:(NSError **)error {
	
	int gitError = git_index_add(self.index, [NSString utf8StringForString:file], 0);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForAddEntryToIndex:gitError];
	}
}

- (void)writeAndReturnError:(NSError **)error {
	
	int gitError = git_index_write(self.index);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForWriteIndex:gitError];
	}
}

@end
