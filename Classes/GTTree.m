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

typedef int(^GTTreeEnumerationBlock)(NSString *root, GTTreeEntry *entry);

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

#pragma mark Contents

static int treewalk_cb(const char *root, const git_tree_entry *git_entry, void *payload) {
	GTTreeEnumerationStruct *enumStruct = (GTTreeEnumerationStruct *)payload;
	NSString *rootString = @(root);
	GTTreeEntry *parentEntry = enumStruct->directoryStructure[rootString];
	GTTree *parentTree = parentEntry ? parentEntry.tree : enumStruct->myself;

	GTTreeEntry *entry = [[GTTreeEntry alloc] initWithEntry:git_entry parentTree:parentTree];
	if ([entry type] == GTObjectTypeTree) {
		NSString *path = [rootString stringByAppendingPathComponent:entry.name];
		enumStruct->directoryStructure[path] = entry;
	}
	return enumStruct->block(rootString, entry);
}


- (BOOL)enumerateContentsWithOptions:(GTTreeEnumerationOptions)option error:(NSError **)error block:(GTTreeEnumerationBlock)block {
	NSParameterAssert(block != nil);

	NSMutableDictionary *structure = [[NSMutableDictionary alloc] initWithCapacity:[self entryCount]];

	GTTreeEnumerationStruct enumStruct = {
		.myself = self,
		.block = block,
		.directoryStructure = structure,
	};

	int gitError = git_tree_walk(self.git_tree, (git_treewalk_mode)option, treewalk_cb, &enumStruct);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to enumerate tree %@", self.SHA];
	}
	return gitError != GIT_OK;
}

- (NSArray *)contents {
	NSError *error = nil;
	__block NSMutableArray *_contents = [NSMutableArray array];
	int gitError = [self enumerateContentsWithOptions:GTTreeEnumerationOptionPre error:&error block:^int(NSString *root, GTTreeEntry *entry) {
		[_contents addObject:entry];
		return [entry type] == GTObjectTypeTree ? 1 : 0;
	}];
	if (gitError < GIT_OK) {
		NSLog(@"%@", error);
		return nil;
	}
	return _contents;
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
