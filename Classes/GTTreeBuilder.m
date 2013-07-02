//
//  GTTreeBuilder.m
//  ObjectiveGitFramework
//
//  Created by Johnnie Walker on 17/05/2013.
//
//  The MIT License
//
//  Copyright (c) 2013 Johnnie Walker
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

#import "GTTreeBuilder.h"
#import "GTTree.h"
#import "GTTreeEntry.h"
#import "GTRepository.h"
#import "NSError+Git.h"

@interface GTTreeBuilder ()
@property (nonatomic, assign, readonly) git_treebuilder *git_treebuilder;
@end

@implementation GTTreeBuilder

#pragma mark Properties

- (NSUInteger)entryCount {
	return (NSUInteger)git_treebuilder_entrycount(self.git_treebuilder);
}

#pragma mark Lifecycle

- (id)initWithTree:(GTTree *)treeOrNil error:(NSError **)error {
	self = [super init];
	if (self == nil) return nil;

	int status = git_treebuilder_create(&_git_treebuilder, treeOrNil.git_tree);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to create tree builder."];
		return nil;
	}

	return self;
}

- (void)dealloc {
	if (_git_treebuilder != NULL) {
		git_treebuilder_free(_git_treebuilder);
		_git_treebuilder = NULL;
	}
}

#pragma mark Modification

- (void)clear {
	git_treebuilder_clear(self.git_treebuilder);	
}

static int filter_callback(const git_tree_entry *entry, void *payload) {
	BOOL (^filterBlock)(const git_tree_entry *entry) = (__bridge __typeof__(filterBlock))payload;
	return filterBlock(entry);
};

- (void)filter:(BOOL (^)(const git_tree_entry *entry))filterBlock {
	NSParameterAssert(filterBlock != nil);

	git_treebuilder_filter(self.git_treebuilder, filter_callback, (__bridge void *)filterBlock);
}

- (GTTreeEntry *)entryWithName:(NSString *)filename {
	NSParameterAssert(filename != nil);

	const git_tree_entry *entry = git_treebuilder_get(self.git_treebuilder, filename.UTF8String);
	if (entry == NULL) return nil;
	
	return [GTTreeEntry entryWithEntry:entry parentTree:nil];
}

- (GTTreeEntry *)addEntryWithSHA:(NSString *)sha filename:(NSString *)filename filemode:(GTFileMode)filemode error:(NSError **)error {
	NSParameterAssert(sha != nil);
	NSParameterAssert(filename != nil);
	
	git_oid oid;	
	int gitError = git_oid_fromstr(&oid, sha.UTF8String);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorForMkStr:gitError];
		return nil;
	}	
	
	const git_tree_entry *entry = NULL;
	int status = git_treebuilder_insert(&entry, self.git_treebuilder, filename.UTF8String, &oid, (git_filemode_t)filemode);
	
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to add entry to tree builder."];
		return nil;
	}
	
	return [GTTreeEntry entryWithEntry:entry parentTree:nil];
}

- (BOOL)removeEntryWithFilename:(NSString *)filename error:(NSError **)error {
	int status = git_treebuilder_remove(self.git_treebuilder, filename.UTF8String);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to remove entry from tree builder by filename."];
	}
	
	return (status == GIT_OK);
}

- (GTTree *)writeTreeToRepository:(GTRepository *)repository error:(NSError **)error {
	git_oid treeOid;
	int status = git_treebuilder_write(&treeOid, repository.git_repository, self.git_treebuilder);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to write as tree in repository."];
		return nil;
	}
	
	git_object *object = NULL;
	status = git_object_lookup(&object, repository.git_repository, &treeOid, GIT_OBJ_TREE);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to lookup tree in repository."];
		return nil;
	}
	
	return [GTObject objectWithObj:object inRepository:repository];	
}

@end
