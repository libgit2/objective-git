//
//  GTIndex.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
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

#import "GTIndex.h"
#import "GTIndexEntry.h"
#import "NSError+Git.h"
#import "GTRepository.h"
#import "GTRepository+Private.h"
#import "GTConfiguration.h"
#import "GTOID.h"
#import "GTTree.h"
#import "EXTScope.h"

// The block synonymous with libgit2's `git_index_matched_path_cb` callback.
typedef BOOL (^GTIndexPathspecMatchedBlock)(NSString *matchedPathspec, NSString *path, BOOL *stop);

@interface GTIndex ()
@property (nonatomic, assign, readonly) git_index *git_index;
@end

@implementation GTIndex

#pragma mark Properties

- (NSURL *)fileURL {
	const char *cPath = git_index_path(self.git_index);
	if (cPath == NULL) return nil;

	NSString *path = [NSFileManager.defaultManager stringWithFileSystemRepresentation:cPath length:strlen(cPath)];
	if (path == nil) return nil;

	return [NSURL fileURLWithPath:path];
}

#pragma mark NSObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> fileURL: %@, entryCount: %lu", NSStringFromClass([self class]), self, self.fileURL, (unsigned long)self.entryCount];
}

#pragma mark Lifecycle

- (void)dealloc {
	if (_git_index != NULL) git_index_free(_git_index);
}

+ (instancetype)inMemoryIndexWithRepository:(GTRepository *)repository error:(NSError **)error {
	git_index *index = NULL;
	int status = git_index_new(&index);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to initialize in-memory index"];
		return nil;
	}

	return [[self alloc] initWithGitIndex:index repository:repository];
}

+ (instancetype)indexWithFileURL:(NSURL *)fileURL repository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(fileURL != nil);
	NSParameterAssert(fileURL.isFileURL);

	git_index *index = NULL;
	int status = git_index_open(&index, fileURL.path.fileSystemRepresentation);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to initialize index with URL %@", fileURL];
		return nil;
	}

	return [[self alloc] initWithGitIndex:index repository:repository];
}

- (id)initWithGitIndex:(git_index *)index repository:(GTRepository *)repository {
	NSParameterAssert(index != NULL);
	NSParameterAssert(repository != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_index = index;
	_repository = repository;

	return self;
}

#pragma mark Entries

- (NSUInteger)entryCount {
	return git_index_entrycount(self.git_index);
}

- (BOOL)refresh:(NSError **)error {
	int status = git_index_read(self.git_index, 1);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to refresh index."];
		return NO;
	}

	return YES;
}

- (BOOL)clear:(NSError **)error {
	int gitError = git_index_clear(self.git_index);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to clear index"];
		return NO;
	}
	return YES;
}

- (GTIndexEntry *)entryAtIndex:(NSUInteger)index {
	const git_index_entry *entry = git_index_get_byindex(self.git_index, (unsigned int)index);
	if (entry == NULL) return nil;

	return [[GTIndexEntry alloc] initWithGitIndexEntry:entry];
}

- (GTIndexEntry *)entryWithName:(NSString *)name {
	return [self entryWithName:name error:NULL];
}

- (GTIndexEntry *)entryWithName:(NSString *)name error:(NSError **)error {
	size_t pos = 0;
	int gitError = git_index_find(&pos, self.git_index, name.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"%@ not found in index", name];
		return NULL;
	}
	return [self entryAtIndex:pos];
}

- (BOOL)addEntry:(GTIndexEntry *)entry error:(NSError **)error {
	int status = git_index_add(self.git_index, entry.git_index_entry);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to add entry to index."];
		return NO;
	}

	return YES;
}

- (BOOL)addFile:(NSString *)file error:(NSError **)error {
	NSString *unicodeString = [self composedUnicodeStringWithString:file];

	int status = git_index_add_bypath(self.git_index, unicodeString.UTF8String);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to add file %@ to index.", file];
		return NO;
	}

	return YES;
}

- (BOOL)addContentsOfTree:(GTTree *)tree error:(NSError **)error {
	NSParameterAssert(tree != nil);

	int status = git_index_read_tree(self.git_index, tree.git_tree);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to read tree %@ into index.", tree];
		return NO;
	}

	return YES;
}

- (BOOL)removeFile:(NSString *)file error:(NSError **)error {
	NSString *unicodeString = [self composedUnicodeStringWithString:file];

	int status = git_index_remove_bypath(self.git_index, unicodeString.UTF8String);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to remove file %@ from index.", file];
		return NO;
	}
	
	return YES;
}

- (BOOL)write:(NSError **)error {
	int status = git_index_write(self.git_index);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to write index."];
		return NO;
	}

	return YES;
}

- (GTTree *)writeTree:(NSError **)error {
	git_oid oid;
  
	int status = git_index_write_tree(&oid, self.git_index);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to write index."];
		return NULL;
	}

	return [self.repository lookUpObjectByGitOid:&oid objectType:GTObjectTypeTree error:NULL];
}

- (GTTree *)writeTreeToRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(repository != nil);
	git_oid oid;
	
	int status = git_index_write_tree_to(&oid, self.git_index, repository.git_repository);
	if (status != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:status description:@"Failed to write index to repository %@", repository];
		return NULL;
	}
	
	return [repository lookUpObjectByGitOid:&oid objectType:GTObjectTypeTree error:NULL];
}

- (NSArray *)entries {
	NSMutableArray *entries = [NSMutableArray arrayWithCapacity:self.entryCount];
	for (NSUInteger i = 0; i < self.entryCount; i++) {
		[entries addObject:[self entryAtIndex:i]];
	}

	return entries;
}

#pragma mark Conflicts

- (BOOL)hasConflicts {
	return (BOOL)git_index_has_conflicts(self.git_index);
}

- (BOOL)enumerateConflictedFilesWithError:(NSError **)error usingBlock:(void (^)(GTIndexEntry *ancestor, GTIndexEntry *ours, GTIndexEntry *theirs, BOOL *stop))block {
	NSParameterAssert(block != nil);
	if (!self.hasConflicts) return YES;
	
	git_index_conflict_iterator *iterator = NULL;
	int returnCode = git_index_conflict_iterator_new(&iterator, self.git_index);
	if (returnCode != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnCode description:NSLocalizedString(@"Could not create git index iterator.", nil)];
		return NO;
	}
	
	@onExit {
		if (iterator != NULL) git_index_conflict_iterator_free(iterator);
	};
	
	while (YES) {
		const git_index_entry *ancestor = NULL;
		const git_index_entry *ours = NULL;
		const git_index_entry *theirs = NULL;
		
		returnCode = git_index_conflict_next(&ancestor, &ours, &theirs, iterator);
		if (returnCode == GIT_ITEROVER) break;
		
		if (returnCode != GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:returnCode description:NSLocalizedString(@"Could not iterate conflict.", nil)];
			return NO;
		}
		
		GTIndexEntry *blockAncestor;
		if (ancestor != NULL) {
			blockAncestor = [[GTIndexEntry alloc] initWithGitIndexEntry:ancestor];
		}

		GTIndexEntry *blockOurs;
		if (ours != NULL) {
			blockOurs = [[GTIndexEntry alloc] initWithGitIndexEntry:ours];
		}

		GTIndexEntry *blockTheirs;
		if (theirs != NULL) {
			blockTheirs = [[GTIndexEntry alloc] initWithGitIndexEntry:theirs];
		}

		BOOL stop = NO;
		block(blockAncestor, blockOurs, blockTheirs, &stop);
		if (stop) break;
	}
	
	return YES;
}

struct GTIndexPathspecMatchedInfo {
	__unsafe_unretained GTIndexPathspecMatchedBlock block;
	BOOL shouldAbortImmediately;
};

- (BOOL)updatePathspecs:(NSArray *)pathspecs error:(NSError **)error passingTest:(GTIndexPathspecMatchedBlock)block {
	NSAssert(self.repository.isBare == NO, @"This method only works with non-bare repositories.");
	
	const git_strarray strarray = pathspecs.git_strarray;
	struct GTIndexPathspecMatchedInfo payload = {
		.block = block,
		.shouldAbortImmediately = NO,
	};

	int returnCode = git_index_update_all(self.git_index, &strarray, (block != nil ? GTIndexPathspecMatchFound : NULL), &payload);
	if (returnCode != GIT_OK && returnCode != GIT_EUSER) {
		if (error != nil) *error = [NSError git_errorFor:returnCode description:NSLocalizedString(@"Could not update index.", nil)];
		return NO;
	}
	
	return YES;
}

int GTIndexPathspecMatchFound(const char *path, const char *matched_pathspec, void *payload) {
	struct GTIndexPathspecMatchedInfo *info = payload;
	GTIndexPathspecMatchedBlock block = info->block;
	if (info->shouldAbortImmediately) {
		return GIT_EUSER;
	}
	
	BOOL shouldStop = NO;
	NSString *matchedPathspec = (matched_pathspec != nil ? @(matched_pathspec): nil);
	BOOL shouldUpdate = block(matchedPathspec, @(path), &shouldStop);
	
	if (shouldUpdate) {
		if (shouldStop) {
			info->shouldAbortImmediately = YES;
		}
		return 0;
	} else if (shouldStop) {
		return GIT_EUSER;
	} else {
		return 1;
	}
}


- (NSString *)composedUnicodeStringWithString:(NSString *)string {
      GTConfiguration *repoConfig = [self.repository configurationWithError:NULL];
      bool shouldPrecompose = [repoConfig boolForKey:@"core.precomposeunicode"];

      return (shouldPrecompose ? [string precomposedStringWithCanonicalMapping] : [string decomposedStringWithCanonicalMapping]);
}

@end
