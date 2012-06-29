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
#import "NSError+Git.h"


@implementation GTTree

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> numberOfEntries: %lu", NSStringFromClass([self class]), self, (unsigned long)[self numberOfEntries]];
}


#pragma mark API

- (NSUInteger)numberOfEntries {
	return (NSUInteger) git_tree_entrycount(self.git_tree);
}

- (GTTreeEntry *)createEntryWithEntry:(const git_tree_entry *)entry {
	return [GTTreeEntry entryWithEntry:entry parentTree:self];
}

- (GTTreeEntry *)entryAtIndex:(NSUInteger)index {
	return [self createEntryWithEntry:git_tree_entry_byindex(self.git_tree, (unsigned int) index)];
}

- (GTTreeEntry *)entryWithName:(NSString *)name {
	return [self createEntryWithEntry:git_tree_entry_byname(self.git_tree, [name UTF8String])];
}

- (git_tree *)git_tree {
	return (git_tree *) self.git_object;
}

/*
- (GTTreeEntry *)addEntryWithSha:(NSString *)sha filename:(NSString *)filename mode:(NSInteger *)mode error:(NSError **)error {
	
	git_tree_entry *newEntry;
	git_oid oid;
 
    BOOL success = [sha git_getOid:&oid error:error];
	if(!success) return nil;
	
	int gitError = git_tree_add_entry(&newEntry, self.tree, &oid, [filename UTF8String], (int)mode);
	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError gitErrorForAddTreeEntry:gitError];
		return nil;
	}
	
	return [self createEntryWithEntry:newEntry];
}
*/
@end
