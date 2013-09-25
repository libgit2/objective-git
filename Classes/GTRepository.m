//
//  GTRepository.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/17/11.
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

#import "GTRepository.h"
#import "GTBranch.h"
#import "GTCommit.h"
#import "GTConfiguration+Private.h"
#import "GTConfiguration.h"
#import "GTEnumerator.h"
#import "GTIndex.h"
#import "GTObject.h"
#import "GTObjectDatabase.h"
#import "GTOID.h"
#import "GTSignature.h"
#import "GTSubmodule.h"
#import "GTTag.h"
#import "NSError+Git.h"
#import "NSString+Git.h"
#import "GTDiffFile.h"

NSString *const GTRepositoryCloneOptionsBare = @"GTRepositoryCloneOptionsBare";
NSString *const GTRepositoryCloneOptionsCheckout = @"GTRepositoryCloneOptionsCheckout";
NSString *const GTRepositoryCloneOptionsTransportFlags = @"GTRepositoryCloneOptionsTransportFlags";

// The type of block passed to -enumerateSubmodulesRecursively:usingBlock:.
typedef void (^GTRepositorySubmoduleEnumerationBlock)(GTSubmodule *submodule, BOOL *stop);

typedef void (^GTRepositoryTagEnumerationBlock)(GTTag *tag, BOOL *stop);

// Used as a payload for submodule enumeration.
//
// recursive        - Whether submodule enumeration should recurse.
// parentRepository - The repository that the submodule is contained within.
// block            - The block to invoke for each submodule.
typedef struct {
	BOOL recursive;
	__unsafe_unretained GTRepository *parentRepository;
	__unsafe_unretained GTRepositorySubmoduleEnumerationBlock block;
} GTRepositorySubmoduleEnumerationInfo;


@interface GTRepository ()
@property (nonatomic, assign, readonly) git_repository *git_repository;
@end

@implementation GTRepository

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> fileURL: %@", self.class, self, self.fileURL];
}

- (BOOL)isEqual:(GTRepository *)repo {
	if (![repo isKindOfClass:GTRepository.class]) return NO;
	return [self.gitDirectoryURL isEqual:repo.gitDirectoryURL];
}

- (void)dealloc {
	if (_git_repository != NULL) {
		git_repository_free(_git_repository);
		_git_repository = NULL;
	}
}

#pragma mark API

+ (BOOL)isAGitDirectory:(NSURL *)directory {
	NSFileManager *fm = [[NSFileManager alloc] init];
	BOOL isDir = NO;
	NSURL *headFileURL = [directory URLByAppendingPathComponent:@"HEAD"];

	if ([fm fileExistsAtPath:headFileURL.path isDirectory:&isDir] && !isDir) {
		NSURL *objectsDir = [directory URLByAppendingPathComponent:@"objects"];
		if ([fm fileExistsAtPath:objectsDir.path isDirectory:&isDir] && isDir) {
			return YES;
		}
	}

	return NO;
}

+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL error:(NSError **)error {
	return [self initializeEmptyRepositoryAtURL:localFileURL bare:NO error:error];
}

+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL bare:(BOOL)bare error:(NSError **)error {
	if (![localFileURL isFileURL] || localFileURL.path == nil) {
		if (error != NULL) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnsupportedSchemeError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid file path URL to initialize repository.", @"") }];
		return NO;
	}

	const char *path = localFileURL.path.UTF8String;

	git_repository *r;
	int gitError = git_repository_init(&r, path, bare);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to initialize empty repository at URL %@.", localFileURL];
	}

	return gitError == GIT_OK;
}

+ (id)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error {
	return [[self alloc] initWithURL:localFileURL error:error];
}

- (id)initWithGitRepository:(git_repository *)repository {
	NSParameterAssert(repository != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_repository = repository;

	return self;
}

- (id)initWithURL:(NSURL *)localFileURL error:(NSError **)error {
	if (![localFileURL isFileURL] || localFileURL.path == nil) {
		if (error != NULL) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnsupportedSchemeError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid file path URL to open.", @"") }];
		return nil;
	}

	git_repository *r;
	int gitError = git_repository_open(&r, localFileURL.path.UTF8String);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to open repository at URL %@.", localFileURL];
		return nil;
	}

	return [self initWithGitRepository:r];
}

static void checkoutProgressCallback(const char *path, size_t completedSteps, size_t totalSteps, void *payload) {
	if (payload == NULL) return;
	void (^block)(NSString *, NSUInteger, NSUInteger) = (__bridge id)payload;
	NSString *nsPath = (path != NULL ? [NSString stringWithUTF8String:path] : nil);
	block(nsPath, completedSteps, totalSteps);
}

static int transferProgressCallback(const git_transfer_progress *progress, void *payload) {
	if (payload == NULL) return 0;
	void (^block)(const git_transfer_progress *) = (__bridge id)payload;
	block(progress);

	return 0;
}

+ (id)cloneFromURL:(NSURL *)originURL toWorkingDirectory:(NSURL *)workdirURL options:(NSDictionary *)options error:(NSError **)error transferProgressBlock:(void (^)(const git_transfer_progress *))transferProgressBlock checkoutProgressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))checkoutProgressBlock {

	git_clone_options cloneOptions = GIT_CLONE_OPTIONS_INIT;

	NSNumber *bare = options[GTRepositoryCloneOptionsBare];
	cloneOptions.bare = bare == nil ? 0 : bare.boolValue;

	NSNumber *transportFlags = options[GTRepositoryCloneOptionsTransportFlags];
	cloneOptions.transport_flags = transportFlags == nil ? 0 : transportFlags.intValue;

	NSNumber *checkout = options[GTRepositoryCloneOptionsCheckout];
	BOOL withCheckout = checkout == nil ? YES : checkout.boolValue;

	if (withCheckout) {
		git_checkout_opts checkoutOptions = GIT_CHECKOUT_OPTS_INIT;
		checkoutOptions.checkout_strategy = GIT_CHECKOUT_SAFE_CREATE;
		checkoutOptions.progress_cb = checkoutProgressCallback;
		checkoutOptions.progress_payload = (__bridge void *)checkoutProgressBlock;
		cloneOptions.checkout_opts = checkoutOptions;
	}

	cloneOptions.fetch_progress_cb = transferProgressCallback;
	cloneOptions.fetch_progress_payload = (__bridge void *)transferProgressBlock;

	const char *remoteURL = originURL.absoluteString.UTF8String;
	const char *workingDirectoryPath = workdirURL.path.UTF8String;
	git_repository *repository;
	int gitError = git_clone(&repository, remoteURL, workingDirectoryPath, &cloneOptions);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to clone repository from %@ to %@", originURL, workdirURL];
		return nil;
	}

	return [[self alloc] initWithGitRepository:repository];
}


+ (NSString *)hash:(NSString *)data objectType:(GTObjectType)type error:(NSError **)error {
	git_oid oid;

	int gitError = git_odb_hash(&oid, [data UTF8String], [data length], (git_otype) type);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get hash for object."];
		return nil;
	}

	return [GTOID oidWithGitOid:&oid].SHA;
}

- (id)lookupObjectByGitOid:(const git_oid *)oid objectType:(GTObjectType)type error:(NSError **)error {
	git_object *obj;

	int gitError = git_object_lookup(&obj, self.git_repository, oid, (git_otype)type);
	if (gitError < GIT_OK) {
		if (error != NULL) {
			char oid_str[GIT_OID_HEXSZ+1];
			git_oid_tostr(oid_str, sizeof(oid_str), oid);
			*error = [NSError git_errorFor:gitError description:@"Failed to lookup object %s in repository.", oid_str];
		}
		return nil;
	}

    return [GTObject objectWithObj:obj inRepository:self];
}

- (id)lookupObjectByGitOid:(const git_oid *)oid error:(NSError **)error {
	return [self lookupObjectByGitOid:oid objectType:GTObjectTypeAny error:error];
}

- (id)lookupObjectByOID:(GTOID *)oid objectType:(GTObjectType)type error:(NSError **)error {
	return [self lookupObjectByGitOid:oid.git_oid objectType:type error:error];
}

- (id)lookupObjectByOID:(GTOID *)oid error:(NSError **)error {
	return [self lookupObjectByOID:oid objectType:GTObjectTypeAny error:error];
}

- (id)lookupObjectBySHA:(NSString *)sha objectType:(GTObjectType)type error:(NSError **)error {
	GTOID *oid = [[GTOID alloc] initWithSHA:sha error:error];
	if (!oid) return nil;

	return [self lookupObjectByOID:oid objectType:type error:error];
}

- (id)lookupObjectBySHA:(NSString *)sha error:(NSError **)error {
	return [self lookupObjectBySHA:sha objectType:GTObjectTypeAny error:error];
}

- (id)lookupObjectByRefspec:(NSString *)spec error:(NSError **)error {
	git_object *obj;
	int gitError = git_revparse_single(&obj, self.git_repository, spec.UTF8String);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to lookup object by refspec %@.", spec];
		return nil;
	}
	return [GTObject objectWithObj:obj inRepository:self];
}

struct gitPayload {
	__unsafe_unretained GTRepository *repository;
	__unsafe_unretained GTRepositoryStatusBlock block;
};

static int file_status_callback(const char *relativeFilePath, unsigned int gitStatus, void *rawPayload) {
	struct gitPayload *payload = rawPayload;

	NSURL *fileURL = [payload->repository.fileURL URLByAppendingPathComponent:@(relativeFilePath)];

	BOOL stop = NO;
	payload->block(fileURL, gitStatus, &stop);

	return stop ? GIT_ERROR : GIT_OK;
}

- (void)enumerateFileStatusUsingBlock:(GTRepositoryStatusBlock)block {
	NSParameterAssert(block != NULL);

	// we want to pass several things into the C callback function:
	// ourselves and the user's supplied block. Throw it into a struct
	// and pass a pointer to the struct to the C callback function

	struct gitPayload fileStatusPayload;

	fileStatusPayload.repository = self;
	fileStatusPayload.block = block;

	git_status_foreach(self.git_repository, file_status_callback, &fileStatusPayload);
}

- (BOOL)isWorkingDirectoryClean {
	__block BOOL clean = YES;
	[self enumerateFileStatusUsingBlock:^(NSURL *fileURL, GTRepositoryFileStatus fileStatus, BOOL *stop) {
		// first, have items been deleted?
		// (not sure why we would get WT_DELETED AND INDEX_NEW in this situation, but that's what I got experimentally. WD-rpw, 02-23-2012
		if ((fileStatus == (GTRepositoryFileStatusWorkingTreeDeleted) || (fileStatus == (GTRepositoryFileStatusWorkingTreeDeleted | GTRepositoryFileStatusIndexNew)))) {
			clean = NO;
			*stop = YES;
		}

		// any untracked files?
		if (fileStatus == GTRepositoryFileStatusWorkingTreeNew) {
			clean = NO;
			*stop = YES;
		}

		// next, have items been modified?
		if ((fileStatus == GTRepositoryFileStatusIndexModified) || (fileStatus == GTRepositoryFileStatusWorkingTreeModified)) {
			clean = NO;
			*stop = YES;
		}
	}];

	return clean;
}

- (GTReference *)headReferenceWithError:(NSError **)error {
	git_reference *headRef;
	int gitError = git_repository_head(&headRef, self.git_repository);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get HEAD"];
		return nil;
	}

	return [[GTReference alloc] initWithGitReference:headRef repository:self];
}

- (NSArray *)localBranchesWithError:(NSError **)error {
	return [self branchesWithPrefix:[GTBranch localNamePrefix] error:error];
}

- (NSArray *)remoteBranchesWithError:(NSError **)error {
	NSArray *remoteBranches = [self branchesWithPrefix:[GTBranch remoteNamePrefix] error:error];
	if (remoteBranches == nil) return nil;

	NSMutableArray *filteredList = [NSMutableArray arrayWithCapacity:remoteBranches.count];
	for (GTBranch *branch in remoteBranches) {
		if (![branch.shortName isEqualToString:@"HEAD"]) {
			[filteredList addObject:branch];
		}
	}

	return filteredList;
}

- (NSArray *)branchesWithPrefix:(NSString *)prefix error:(NSError **)error {
	NSArray *references = [self referenceNamesWithError:error];
	if (references == nil) return nil;

	NSMutableArray *branches = [NSMutableArray array];
	for (NSString *ref in references) {
		if ([ref hasPrefix:prefix]) {
			GTBranch *b = [GTBranch branchWithName:ref repository:self error:error];
			if (b != nil) [branches addObject:b];
		}
	}

	return branches;
}

- (NSArray *)allBranchesWithError:(NSError **)error {
	NSMutableArray *allBranches = [NSMutableArray array];
	NSArray *localBranches = [self localBranchesWithError:error];
	NSArray *remoteBranches = [self remoteBranchesWithError:error];
	if (localBranches == nil || remoteBranches == nil) return nil;

	[allBranches addObjectsFromArray:localBranches];

	// we want to add the remote branches that we don't already have as a local branch
	NSMutableDictionary *shortNamesToBranches = [NSMutableDictionary dictionary];
	for (GTBranch *branch in localBranches) {
		[shortNamesToBranches setObject:branch forKey:branch.shortName];
	}

	for (GTBranch *branch in remoteBranches) {
		GTBranch *localBranch = [shortNamesToBranches objectForKey:branch.shortName];
		if (localBranch == nil) {
			[allBranches addObject:branch];
		}
	}

    return allBranches;
}

struct GTRepositoryTagEnumerationInfo {
	__unsafe_unretained GTRepository *myself;
	__unsafe_unretained GTRepositoryTagEnumerationBlock block;
};

static int GTRepositoryForeachTagCallback(const char *name, git_oid *oid, void *payload) {
	struct GTRepositoryTagEnumerationInfo *info = payload;
	GTTag *tag = (GTTag *)[info->myself lookupObjectByGitOid:oid objectType:GTObjectTypeTag error:NULL];

	BOOL stop = NO;
	info->block(tag, &stop);

	return stop ? GIT_EUSER : 0;
}

- (BOOL)enumerateTags:(NSError **)error block:(GTRepositoryTagEnumerationBlock)block {
	NSParameterAssert(block != nil);

	struct GTRepositoryTagEnumerationInfo payload = {
		.myself = self,
		.block = block,
	};
	int gitError = git_tag_foreach(self.git_repository, GTRepositoryForeachTagCallback, &payload);
	if (gitError != GIT_OK && gitError != GIT_EUSER) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to enumerate tags"];
		return NO;
	}

	return YES;
}

- (NSArray *)allTagsWithError:(NSError **)error {
	NSMutableArray *tagArray = [NSMutableArray array];
	BOOL success = [self enumerateTags:error block:^(GTTag *tag, BOOL *stop) {
		[tagArray addObject:tag];
	}];
	return success == YES ? tagArray : nil;
}

- (NSUInteger)numberOfCommitsInCurrentBranch:(NSError **)error {
	GTBranch *currentBranch = [self currentBranchWithError:error];
	if (currentBranch == nil) return NSNotFound;

	return [currentBranch numberOfCommitsWithError:error];
}

- (GTBranch *)createBranchNamed:(NSString *)name fromReference:(GTReference *)ref error:(NSError **)error {
	// make sure the ref is up to date before we branch off it, otherwise we could branch off an older sha
	ref = [ref reloadedReferenceWithError:error];
	if (ref == nil) return nil;
	
	GTReference *newRef = [GTReference referenceByCreatingReferenceNamed:[NSString stringWithFormat:@"%@%@", [GTBranch localNamePrefix], name] fromReferenceTarget:[ref.resolvedTarget SHA] inRepository:self error:error];
	if (newRef == nil) return nil;

	return [GTBranch branchWithReference:newRef repository:self];
}

- (BOOL)isEmpty {
	return (BOOL) git_repository_is_empty(self.git_repository);
}

- (GTBranch *)currentBranchWithError:(NSError **)error {
	GTReference *head = [self headReferenceWithError:error];
	if (head == nil) return nil;

	return [GTBranch branchWithReference:head repository:self];
}

- (NSArray *)localCommitsRelativeToRemoteBranch:(GTBranch *)remoteBranch error:(NSError **)error {
	GTBranch *localBranch = [self currentBranchWithError:error];
	if (localBranch == nil) return nil;

	return [localBranch uniqueCommitsRelativeToBranch:remoteBranch error:error];
}

- (NSArray *)referenceNamesWithError:(NSError **)error {
	git_strarray array;
	int gitError = git_reference_list(&array, self.git_repository);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to list all references."];
		return nil;
	}

	NSMutableArray *references = [NSMutableArray arrayWithCapacity:array.count];
	for (NSUInteger i = 0; i < array.count; i++) {
		NSString *refName = @(array.strings[i]);
		if (refName == nil) continue;

		[references addObject:refName];
	}

	git_strarray_free(&array);

	return references;
}

- (NSURL *)fileURL {
	const char *path = git_repository_workdir(self.git_repository);
	// bare repository, you may be looking for gitDirectoryURL
	if (path == NULL) return nil;

	return [NSURL fileURLWithPath:@(path) isDirectory:YES];
}

- (NSURL *)gitDirectoryURL {
	const char *path = git_repository_path(self.git_repository);
	if (path == NULL) return nil;

	return [NSURL fileURLWithPath:@(path) isDirectory:YES];
}

- (BOOL)isBare {
	return self.git_repository && git_repository_is_bare(self.git_repository);
}

- (BOOL)isHEADDetached {
	return (BOOL) git_repository_head_detached(self.git_repository);
}

- (BOOL)isHEADUnborn {
	return (BOOL)git_repository_head_unborn(self.git_repository);
}

- (BOOL)resetToCommit:(GTCommit *)commit withResetType:(GTRepositoryResetType)resetType error:(NSError **)error {
    NSParameterAssert(commit != nil);

    int result = git_reset(self.git_repository, commit.git_object, (git_reset_t)resetType);
    if (result == GIT_OK) return YES;

    if (error != NULL) *error = [NSError git_errorFor:result description:@"Failed to reset repository to commit %@.", commit.SHA];

    return NO;
}

- (NSString *)preparedMessageWithError:(NSError **)error {
	void (^setErrorFromCode)(int) = ^(int errorCode) {
		if (errorCode == 0 || errorCode == GIT_ENOTFOUND) {
			// Not an error.
			return;
		}

		if (error != NULL) {
			*error = [NSError git_errorFor:errorCode description:@"Failed to read prepared message."];
		}
	};

	int errorCode = git_repository_message(NULL, 0, self.git_repository);
	if (errorCode <= 0) {
		setErrorFromCode(errorCode);
		return nil;
	}

	size_t size = (size_t)errorCode;
	if (size == 1) {
		// This is just the NUL terminator. The message must be an empty string.
		return @"";
	}

	void *bytes = malloc(size);
	if (bytes == nil) return nil;

	// Although documented to return the size of the read data, this function
	// actually returns the full size of the message, which may not match what
	// gets copied into `bytes` (like if the file changed since we checked it
	// originally). So we don't really care about that number except for error
	// checking.
	//
	// See libgit2/libgit2#1519.
	errorCode = git_repository_message(bytes, size, self.git_repository);
	if (errorCode <= 0) {
		setErrorFromCode(errorCode);
		free(bytes);
		return nil;
	}

	NSString *message = [[NSString alloc] initWithBytesNoCopy:bytes length:size - 1 encoding:NSUTF8StringEncoding freeWhenDone:YES];
	if (message == nil) {
		free(bytes);
	}

	return message;
}

- (GTCommit *)mergeBaseBetweenFirstOID:(GTOID *)firstOID secondOID:(GTOID *)secondOID error:(NSError **)error {
	NSParameterAssert(firstOID != nil);
	NSParameterAssert(secondOID != nil);

	git_oid mergeBase;
	int errorCode = git_merge_base(&mergeBase, self.git_repository, firstOID.git_oid, secondOID.git_oid);
	if (errorCode < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:errorCode description:@"Failed to find merge base between commits %@ and %@.", firstOID.SHA, secondOID.SHA];
		return nil;
	}
	
	return [self lookupObjectByGitOid:&mergeBase objectType:GTObjectTypeCommit error:error];
}

- (GTObjectDatabase *)objectDatabaseWithError:(NSError **)error {
	return [[GTObjectDatabase alloc] initWithRepository:self error:error];
}

- (GTConfiguration *)configurationWithError:(NSError **)error {
	git_config *config = NULL;
	int gitError = git_repository_config(&config, self.git_repository);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get config for repository."];
		return nil;
	}

	return [[GTConfiguration alloc] initWithGitConfig:config repository:self];
}

- (GTIndex *)indexWithError:(NSError **)error {
	git_index *index = NULL;
	int gitError = git_repository_index(&index, self.git_repository);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get index for repository."];
		return NO;
	}

	return [[GTIndex alloc] initWithGitIndex:index repository:self];
}

#pragma mark Submodules

static int submoduleEnumerationCallback(git_submodule *git_submodule, const char *name, void *payload) {
	GTRepositorySubmoduleEnumerationInfo *info = payload;

	GTSubmodule *submodule = [[GTSubmodule alloc] initWithGitSubmodule:git_submodule parentRepository:info->parentRepository];

	BOOL stop = NO;
	info->block(submodule, &stop);
	if (stop) return 1;

	if (info->recursive) {
		[[submodule submoduleRepository:NULL] enumerateSubmodulesRecursively:YES usingBlock:info->block];
	}

	return 0;
}

- (BOOL)reloadSubmodules:(NSError **)error {
	int gitError = git_submodule_reload_all(self.git_repository);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to reload submodules."];
		return NO;
	}

	return YES;
}

- (void)enumerateSubmodulesRecursively:(BOOL)recursive usingBlock:(void (^)(GTSubmodule *submodule, BOOL *stop))block {
	NSParameterAssert(block != nil);

	// Enumeration is synchronous, so it's okay for the objects here to be
	// unretained for the duration.
	GTRepositorySubmoduleEnumerationInfo info = {
		.recursive = recursive,
		.parentRepository = self,
		.block = block
	};

	git_submodule_foreach(self.git_repository, &submoduleEnumerationCallback, &info);
}

- (GTSubmodule *)submoduleWithName:(NSString *)name error:(NSError **)error {
	NSParameterAssert(name != nil);

	git_submodule *submodule;
	int gitError = git_submodule_lookup(&submodule, self.git_repository, name.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to look up submodule %@.", name];
		return nil;
	}

	return [[GTSubmodule alloc] initWithGitSubmodule:submodule parentRepository:self];
}

#pragma mark User

- (GTSignature *)userSignatureForNow {
	GTConfiguration *configuration = [self configurationWithError:NULL];
	NSString *name = [configuration stringForKey:@"user.name"];
	if (name == nil) {
		name = NSFullUserName() ?: NSUserName() ?: @"Nobody";
	}

	NSString *email = [configuration stringForKey:@"user.email"];
	if (email == nil) {
		NSString *username = NSUserName() ?: @"nobody";
		NSString *domain = NSProcessInfo.processInfo.hostName ?: @"nowhere.local";
		email = [NSString stringWithFormat:@"%@@%@", username, domain];
	}

	return [[GTSignature alloc] initWithName:name email:email time:[NSDate date]];
}

#pragma mark Tagging

- (BOOL)createLightweightTagNamed:(NSString *)tagName target:(GTObject *)target error:(NSError **)error {
	NSParameterAssert(tagName != nil);
	NSParameterAssert(target != nil);

	git_oid oid;
	int gitError = git_tag_create_lightweight(&oid, self.git_repository, tagName.UTF8String, target.git_object, 0);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Cannot create lightweight tag"];
		return NO;
	}

	return YES;
}

- (GTOID *)OIDByCreatingTagNamed:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error {
	git_oid oid;
	int gitError = git_tag_create(&oid, self.git_repository, [tagName UTF8String], theTarget.git_object, theTagger.git_signature, [theMessage UTF8String], 0);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create tag in repository"];
		return nil;
	}

	return [GTOID oidWithGitOid:&oid];
}

- (GTTag *)createTagNamed:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error {
	GTOID *oid = [self OIDByCreatingTagNamed:tagName target:theTarget tagger:theTagger message:theMessage error:error];
	return oid ? [self lookupObjectByOID:oid objectType:GTObjectTypeTag error:error] : nil;
}

#pragma mark Checkout

// The type of block passed to -checkout:strategy:progressBlock:notifyBlock:notifyFlags:error: for progress reporting
typedef void (^GTCheckoutProgressBlock)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps);

// The type of block passed to -checkout:strategy:progressBlock:notifyBlock:notifyFlags:error: for notification reporting
typedef int  (^GTCheckoutNotifyBlock)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir);

static int checkoutNotifyCallback(git_checkout_notify_t why, const char *path, const git_diff_file *baseline, const git_diff_file *target, const git_diff_file *workdir, void *payload) {
	if (payload == NULL) return 0;
	GTCheckoutNotifyBlock block = (__bridge id)payload;
	NSString *nsPath = (path != NULL ? @(path) : nil);
	GTDiffFile *gtBaseline = (baseline != NULL ? [[GTDiffFile alloc] initWithGitDiffFile:*baseline] : nil);
	GTDiffFile *gtTarget = (target != NULL ? [[GTDiffFile alloc] initWithGitDiffFile:*target] : nil);
	GTDiffFile *gtWorkdir = (workdir != NULL ? [[GTDiffFile alloc] initWithGitDiffFile:*workdir] : nil);
	return block((GTCheckoutNotifyFlags)why, nsPath, gtBaseline, gtTarget, gtWorkdir);
}

- (BOOL)moveHEADToReference:(GTReference *)reference error:(NSError **)error {
	NSParameterAssert(reference != nil);
	
	int gitError = git_repository_set_head(self.git_repository, reference.name.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to move HEAD to reference %@", reference.name];
	}
	
	return gitError == GIT_OK;
}

- (BOOL)moveHEADToCommit:(GTCommit *)commit error:(NSError **)error {
	NSParameterAssert(commit != nil);
	
	int gitError = git_repository_set_head_detached(self.git_repository, commit.OID.git_oid);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to move HEAD to commit %@", commit.SHA];
	}
	
	return gitError == GIT_OK;
}

- (BOOL)performCheckoutWithStrategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags error:(NSError **)error progressBlock:(GTCheckoutProgressBlock)progressBlock notifyBlock:(GTCheckoutNotifyBlock)notifyBlock {
	
	git_checkout_opts checkoutOptions = GIT_CHECKOUT_OPTS_INIT;
	
	checkoutOptions.checkout_strategy = strategy;
	checkoutOptions.progress_cb = checkoutProgressCallback;
	checkoutOptions.progress_payload = (__bridge void *)progressBlock;
	
	checkoutOptions.notify_cb = checkoutNotifyCallback;
	checkoutOptions.notify_flags = notifyFlags;
	checkoutOptions.notify_payload = (__bridge void *)notifyBlock;
	
	int gitError = git_checkout_head(self.git_repository, &checkoutOptions);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to checkout tree."];
	}
	
	return gitError == GIT_OK;
}

- (BOOL)checkoutCommit:(GTCommit *)targetCommit strategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags error:(NSError **)error progressBlock:(GTCheckoutProgressBlock)progressBlock notifyBlock:(GTCheckoutNotifyBlock)notifyBlock {
	BOOL success = [self moveHEADToCommit:targetCommit error:error];
	if (success == NO) return NO;
	
	return [self performCheckoutWithStrategy:strategy notifyFlags:notifyFlags error:error progressBlock:progressBlock notifyBlock:notifyBlock];
}

- (BOOL)checkoutReference:(GTReference *)targetReference strategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags error:(NSError **)error progressBlock:(GTCheckoutProgressBlock)progressBlock notifyBlock:(GTCheckoutNotifyBlock)notifyBlock {
	BOOL success = [self moveHEADToReference:targetReference error:error];
	if (success == NO) return NO;
	
	return [self performCheckoutWithStrategy:strategy notifyFlags:notifyFlags error:error progressBlock:progressBlock notifyBlock:notifyBlock];
}

- (BOOL)checkoutCommit:(GTCommit *)target strategy:(GTCheckoutStrategyType)strategy error:(NSError **)error progressBlock:(GTCheckoutProgressBlock)progressBlock {
	return [self checkoutCommit:target strategy:strategy notifyFlags:GTCheckoutNotifyNone error:error progressBlock:progressBlock notifyBlock:nil];
}

- (BOOL)checkoutReference:(GTReference *)target strategy:(GTCheckoutStrategyType)strategy error:(NSError **)error progressBlock:(GTCheckoutProgressBlock)progressBlock {
	return [self checkoutReference:target strategy:strategy notifyFlags:GTCheckoutNotifyNone error:error progressBlock:progressBlock notifyBlock:nil];
}

@end
