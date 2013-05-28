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

@implementation GTTree

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> entryCount: %lu", self.class, self, (unsigned long)self.entryCount];
}

#pragma mark API

- (NSUInteger)entryCount {
	return (NSUInteger)git_tree_entrycount(self.git_tree);
}

- (GTTreeEntry *)createEntryWithEntry:(const git_tree_entry *)entry {
	return [GTTreeEntry entryWithEntry:entry parentTree:self];
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

#pragma mark Merging

- (GTIndex *)merge:(GTTree *)otherTree ancestor:(GTTree *)ancestorTree error:(NSError **)error {
	NSParameterAssert(otherTree != nil);

	git_index *index;
	int result = git_merge_trees(&index, self.repository.git_repository, ancestorTree.git_tree, self.git_tree, otherTree.git_tree, NULL);
	if (result != GIT_OK || index == NULL) {
		if (error != NULL) *error = [NSError git_errorFor:result withAdditionalDescription:@"Couldn't merge trees"];
		return nil;
	}

	return [[GTIndex alloc] initWithGitIndex:index];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len {
	state->mutationsPtr = state->extra;
	state->itemsPtr = buffer;

	if (state->extra[0] == 0) {
		state->extra[1] = git_tree_entrycount(self.git_tree);
	}

	__autoreleasing id *temporaries = (__autoreleasing id *)(void *)buffer;	
	
	NSUInteger initial = state->state;
	for (;state->state < MIN(initial + len, state->extra[1] - initial); state->state++) {
		*temporaries++ = [[GTTreeEntry alloc] initWithEntry:git_tree_entry_byindex(self.git_tree, state->state) parentTree:self];
	}
	
	return state->state - initial;
}

@end
