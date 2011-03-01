//
//  GTTreeEntry.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTTreeEntry.h"
#import "GTObject.h"
#import "GTTree.h"
#import "NSString+Git.h"
#import "NSError+Git.h"

@implementation GTTreeEntry

@synthesize entry;
@synthesize name;
@synthesize attributes;
@synthesize sha;
@synthesize tree;

- (NSString *)name {
	
	return [NSString stringForUTF8String:git_tree_entry_name(self.entry)];
}
- (void)setName:(NSString *)n {
	
	git_tree_entry_set_name(self.entry, [NSString utf8StringForString:n]);
}

- (NSInteger)attributes {
	
	return git_tree_entry_attributes(self.entry);
}
- (void)setAttributes:(NSInteger)attr {
	
	git_tree_entry_set_attributes(self.entry, attr);
}

- (NSString *)sha {
	
	char hex[41];
	git_oid_fmt(hex, git_tree_entry_id(self.entry));
	hex[40] = 0;
	return [NSString stringForUTF8String:hex];
}
- (void)setSha:(NSString *)s {
	
	git_oid oid;
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:s]);
	if(gitError == GIT_SUCCESS){
		git_tree_entry_set_id(self.entry, &oid);
	}
}

- (GTObject *)toObjectAndReturnError:(NSError **)error {
	
	git_object *obj;
	int gitError = git_tree_entry_2object(&obj, self.entry);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForTreeEntryToObject:gitError];
		return nil;
	}
	
	return [GTObject objectInRepo:self.tree.repo withObject:obj];
}

@end
