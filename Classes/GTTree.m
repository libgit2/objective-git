//
//  GTTree.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTTree.h"
#import "GTTreeEntry.h"
#import "NSString+Git.h"
#import "NSError+Git.h"

@interface GTTree()

@property (nonatomic, retain) NSMutableArray *entries;

@end


@implementation GTTree

@synthesize tree;
@synthesize entries;
@synthesize entryCount;

- (git_tree *)tree {
	
	return (git_tree *)self.object;
}

- (NSInteger)entryCount {

	return [[NSNumber numberWithInt:git_tree_entrycount(self.tree)] integerValue];
}

- (void)clear {
	
	git_tree_clear_entries(self.tree);
}

- (GTTreeEntry *)createEntryWithEntry:(git_tree_entry *)entry {
	
	GTTreeEntry *e = [[[GTTreeEntry alloc] init] autorelease];
	e.entry = entry;
	e.tree = self;
	return e;
}

- (GTTreeEntry *)entryAtIndex:(NSInteger)index {
	
	return [self createEntryWithEntry:git_tree_entry_byindex(self.tree, index)];
}

- (GTTreeEntry *)entryByName:(NSString *)name {
	
	return [self createEntryWithEntry:git_tree_entry_byname(self.tree, [NSString utf8StringForString:name])];
}

- (GTTreeEntry *)addEntryWithObjId:(NSString *)ObjId filename:(NSString *)filename mode:(NSInteger *)mode error:(NSError **)error {
	
	git_tree_entry *newEntry;
	git_oid oid;
	
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:ObjId]);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
	
	gitError = git_tree_add_entry(&newEntry, self.tree, &oid, [NSString utf8StringForString:filename], (int)mode);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForAddTreeEntry:gitError];
		return nil;
	}
	
	return [self createEntryWithEntry:newEntry];
}

// Do NOT implement finalize here
// Because GTTree derives from GTObject, the cleanup of self.object
// which is a (git_tree *) in this class will happen in GTObject

@end
