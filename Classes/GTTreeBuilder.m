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
@property (nonatomic, retain, readonly) NSMutableDictionary	*objectData;
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
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to create tree builder with tree %@.", treeOrNil.SHA];
		return nil;
	}

	_objectData	= @{}.mutableCopy;

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

- (GTTreeEntry *)addEntryWithData:(NSData *)data filename:(NSString *)filename filemode:(GTFileMode)filemode error:(NSError **)error {
	NSParameterAssert(data != nil);
	NSParameterAssert(filename != nil);

	GTOID *oid = [GTOID oidByHashingData:data type:GTObjectTypeBlob];

	self.objectData[filename] = @{@"data": data, @"oid":oid, @"filemode":@(filemode)};

	return [self addEntryWithOID:oid filename:filename filemode:filemode error:error];
}

- (GTTreeEntry *)addEntryWithOID:(GTOID *)oid filename:(NSString *)filename filemode:(GTFileMode)filemode error:(NSError **)error {
	NSParameterAssert(oid != nil);
	NSParameterAssert(filename != nil);

	const git_tree_entry *entry = NULL;
	int status = git_treebuilder_insert(&entry, self.git_treebuilder, filename.UTF8String, oid.git_oid, (git_filemode_t)filemode);
	
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to add entry %@ to tree builder.", oid.SHA];
		return nil;
	}
	
	return [GTTreeEntry entryWithEntry:entry parentTree:nil];
}

- (GTTreeEntry *)addEntryWithSHA:(NSString *)sha filename:(NSString *)filename filemode:(GTFileMode)filemode error:(NSError *__autoreleasing *)error {
	GTOID *oid = [[GTOID alloc] initWithSHA:sha error:error];
	if (oid == nil) return nil;
	return [self addEntryWithOID:oid filename:filename filemode:filemode error:error];
}

- (BOOL)removeEntryWithFilename:(NSString *)filename error:(NSError **)error {
	int status = git_treebuilder_remove(self.git_treebuilder, filename.UTF8String);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to remove entry with name %@ from tree builder.", filename];
	}

	[self.objectData removeObjectForKey:filename];
	
	return (status == GIT_OK);
}

- (GTTree *)writeTreeToRepository:(GTRepository *)repository error:(NSError **)error {
	if (self.objectData.count != 0) {
		GTObjectDatabase *odb = [repository objectDatabaseWithError:error];
		if (odb == nil) return nil;

		for (GTOID *oid in self.objectData) {
			NSDictionary *info = self.objectData[oid];

			GTOID *dataOID = [odb oidByInsertingData:info[@"data"]
											 forType:GTObjectTypeBlob
											   error:error];
			if (dataOID == nil) return nil;
		}
	}

	git_oid treeOid;
	int status = git_treebuilder_write(&treeOid, repository.git_repository, self.git_treebuilder);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status withAdditionalDescription:@"Failed to write tree in repository."];
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
