//
//  GTTree.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
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

#import "GTTree.h"
#import "GTTreeEntry.h"
#import "GTRepository.h"
#import "GTIndex.h"
#import "NSError+Git.h"

typedef BOOL (^GTTreeEnumerationBlock)(GTTreeEntry *entry, NSString *root, BOOL *stop);

typedef struct GTTreeEnumerationStruct {
	__unsafe_unretained GTTree *myself;
	__unsafe_unretained GTTreeEnumerationBlock block;
	__unsafe_unretained NSMutableDictionary *directoryStructure;
} GTTreeEnumerationStruct;

@implementation GTTree

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> entryCount: %lu", self.class, self, (unsigned long)self.entryCount];
}

#pragma mark API

- (NSUInteger)entryCount {
	return (NSUInteger)git_tree_entrycount(self.git_tree);
}

- (GTTreeEntry *)createEntryWithEntry:(const git_tree_entry *)entry {
	return (entry != NULL ? [GTTreeEntry entryWithEntry:entry parentTree:self] : nil);
}

- (GTTreeEntry *)entryAtIndex:(NSUInteger)index {
	return [self createEntryWithEntry:git_tree_entry_byindex(self.git_tree, index)];
}

- (GTTreeEntry *)entryWithName:(NSString *)name {
	return [self createEntryWithEntry:git_tree_entry_byname(self.git_tree, name.UTF8String)];
}

- (git_tree *)git_tree {
	return (git_tree *)self.git_object;
}

#pragma mark Entries

static int treewalk_cb(const char *root, const git_tree_entry *git_entry, void *payload) {
	GTTreeEnumerationStruct *enumerationStruct = (GTTreeEnumerationStruct *)payload;
	NSString *rootString = @(root);
	GTTreeEntry *parentEntry = enumerationStruct->directoryStructure[rootString];
	GTTree *parentTree = parentEntry != nil ? parentEntry.tree : enumerationStruct->myself;
	GTTreeEntry *entry = [GTTreeEntry entryWithEntry:git_entry parentTree:parentTree];
	
	if (entry.type == GTObjectTypeTree) {
		NSString *path = [rootString stringByAppendingPathComponent:entry.name];
		enumerationStruct->directoryStructure[path] = entry;
	}
	
	BOOL shouldStop = NO;
	BOOL shouldDescend = enumerationStruct->block(entry, rootString, &shouldStop);
	
	if (shouldStop) {
		return GIT_EUSER;
	} else if (shouldDescend) {
		return 0;
	} else {
		return 1;
	}
}

- (BOOL)enumerateEntriesWithOptions:(GTTreeEnumerationOptions)option error:(NSError **)error block:(GTTreeEnumerationBlock)block {
	NSParameterAssert(block != nil);

	NSMutableDictionary *structure = [[NSMutableDictionary alloc] initWithCapacity:self.entryCount];
	GTTreeEnumerationStruct enumerationStruct = {
		.myself = self,
		.block = block,
		.directoryStructure = structure,
	};

	int gitError = git_tree_walk(self.git_tree, (git_treewalk_mode)option, treewalk_cb, &enumerationStruct);
	if (gitError != GIT_OK && gitError != GIT_EUSER) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to enumerate tree %@", self.SHA];
		return NO;
	}
	
	return YES;
}

- (NSArray *)entries {
	__block NSMutableArray *entries = [NSMutableArray array];
	BOOL success = [self enumerateEntriesWithOptions:GTTreeEnumerationOptionPre error:nil block:^(GTTreeEntry *entry, NSString *root, BOOL *stop) {
		[entries addObject:entry];
		return NO;
	}];
	
	if (!success) {
		return nil;
	}
	return entries;
}

#pragma mark Merging

- (GTIndex *)merge:(GTTree *)otherTree ancestor:(GTTree *)ancestorTree error:(NSError **)error {
	NSParameterAssert(otherTree != nil);

	git_index *index;
	int result = git_merge_trees(&index, self.repository.git_repository, ancestorTree.git_tree, self.git_tree, otherTree.git_tree, NULL);
	if (result != GIT_OK || index == NULL) {
		if (error != NULL) *error = [NSError git_errorFor:result description:@"Failed to merge tree %@ with tree %@", self.SHA, otherTree.SHA];
		return nil;
	}

	return [[GTIndex alloc] initWithGitIndex:index repository:self.repository];
}

@end
