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
#import "GTObjectDatabase.h"
#import "GTOID.h"
#import "NSError+Git.h"
#import "GTOID.h"

@interface GTTreeBuilder ()

@property (nonatomic, assign, readonly) git_treebuilder *git_treebuilder;

// Data to be written with the tree, keyed by the file name. This should only be
// accessed while synchronized on self.
//
// This is needed because we don't want to add the entries to the object
// database until the tree's been written.
@property (nonatomic, strong, readonly) NSMutableDictionary *fileNameToPendingData;

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
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to create tree builder with tree %@.", treeOrNil.SHA];
		return nil;
	}

	_fileNameToPendingData	= [NSMutableDictionary dictionary];

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

- (GTTreeEntry *)entryWithFileName:(NSString *)fileName {
	NSParameterAssert(fileName != nil);

	const git_tree_entry *entry = git_treebuilder_get(self.git_treebuilder, fileName.UTF8String);
	if (entry == NULL) return nil;
	
	return [GTTreeEntry entryWithEntry:entry parentTree:nil];
}

- (GTTreeEntry *)addEntryWithData:(NSData *)data fileName:(NSString *)fileName fileMode:(GTFileMode)fileMode error:(NSError **)error {
	NSParameterAssert(data != nil);
	NSParameterAssert(fileName != nil);

	GTOID *OID = [GTOID OIDByHashingData:data type:GTObjectTypeBlob error:error];
	if (OID == nil) return nil;

	@synchronized (self) {
		self.fileNameToPendingData[fileName] = data;
	}

	return [self addEntryWithOID:OID fileName:fileName fileMode:fileMode error:error];
}

- (GTTreeEntry *)addEntryWithOID:(GTOID *)oid fileName:(NSString *)fileName fileMode:(GTFileMode)fileMode error:(NSError **)error {
	NSParameterAssert(oid != nil);
	NSParameterAssert(fileName != nil);

	const git_tree_entry *entry = NULL;
	int status = git_treebuilder_insert(&entry, self.git_treebuilder, fileName.UTF8String, oid.git_oid, (git_filemode_t)fileMode);
	
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to add entry %@ to tree builder.", oid.SHA];
		return nil;
	}
	
	return [GTTreeEntry entryWithEntry:entry parentTree:nil];
}

- (BOOL)removeEntryWithFileName:(NSString *)fileName error:(NSError **)error {
	int status = git_treebuilder_remove(self.git_treebuilder, fileName.UTF8String);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to remove entry with name %@ from tree builder.", fileName];
	}

	@synchronized (self) {
		[self.fileNameToPendingData removeObjectForKey:fileName];
	}
	
	return status == GIT_OK;
}

- (BOOL)writePendingDataToRepository:(GTRepository *)repository error:(NSError **)error {
	NSDictionary *copied;
	@synchronized (self) {
		copied = [self.fileNameToPendingData copy];
		[self.fileNameToPendingData removeAllObjects];
	}

	if (copied.count != 0) {
		GTObjectDatabase *odb = [repository objectDatabaseWithError:error];
		if (odb == nil) return NO;

		for (NSString *fileName in copied) {
			NSData *data = copied[fileName];
			GTOID *dataOID = [odb writeData:data type:GTObjectTypeBlob error:error];
			if (dataOID == nil) return NO;
		}
	}

	return YES;
}

- (GTTree *)writeTreeToRepository:(GTRepository *)repository error:(NSError **)error {
	BOOL success = [self writePendingDataToRepository:repository error:error];
	if (!success) return nil;

	git_oid treeOid;
	int status = git_treebuilder_write(&treeOid, repository.git_repository, self.git_treebuilder);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to write tree in repository."];
		return nil;
	}
	
	git_object *object = NULL;
	status = git_object_lookup(&object, repository.git_repository, &treeOid, GIT_OBJ_TREE);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to lookup tree in repository."];
		return nil;
	}
	
	return [GTObject objectWithObj:object inRepository:repository];	
}

@end
