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

// The type of block passed to -enumerateSubmodulesRecursively:usingBlock:.
typedef void (^GTRepositorySubmoduleEnumerationBlock)(GTSubmodule *submodule, BOOL *stop);

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

// Cache plain credentials with respect to url authentication callback.
+ (void)cacheCredentialsForCallBack:(NSString*)url username:(NSString*)username password:(NSString*)password;
+ (NSArray *)credentialsForUrl:(NSString*)url;
+ (void)forgetCredentialsForUrl:(NSString*)url;

@end

@implementation GTRepository

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> fileURL: %@", self.class, self, self.fileURL];
}

- (BOOL)isEqual:(GTRepository *)repo {
	if (![repo isKindOfClass:GTRepository.class]) return NO;
	return [self.fileURL isEqual:repo.fileURL];
}

- (void)dealloc {
	if (_git_repository != NULL) {
		git_repository_free(_git_repository);
		_git_repository = NULL;
	}
}

#pragma mark Plain authentication

static NSMutableDictionary *credentials;

+ (void)cacheCredentialsForCallBack:(NSString*)url username:(NSString*)username password:(NSString*)password {
	if (!credentials) {
		credentials = [NSMutableDictionary dictionary];
	}
	NSArray *creds = [NSArray arrayWithObjects:username, password, nil];
	[credentials setObject:creds forKey:url];
}

+ (NSArray *)credentialsForUrl:(NSString*)url {
	return [credentials objectForKey:url];
}

+ (void)forgetCredentialsForUrl:(NSString*)url {
	[credentials removeObjectForKey:url];
}

static int cred_acquire_cb(git_cred **out, const char *url, const char *username_from_url, unsigned int allowed_types, void *payload) {
	NSString *_url = [NSString stringWithUTF8String:url];
	NSArray *creds = [GTRepository credentialsForUrl:_url];
	if (creds) {
		const char* username = [[creds objectAtIndex:0] UTF8String];
		const char* password = [[creds objectAtIndex:1] UTF8String];
		return git_cred_userpass_plaintext_new(out, username, password);
	} else {
		return git_cred_userpass_plaintext_new(out, "", "");
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
	const char *path = localFileURL.path.UTF8String;

	git_repository *r;
	int gitError = git_repository_init(&r, path, 0);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to initialize repository."];
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
		if (error != NULL) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:kCFURLErrorUnsupportedURL userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid file path URL to open.", @"") }];
		return nil;
	}

	git_repository *r;
	int gitError = git_repository_open(&r, localFileURL.path.UTF8String);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to open repository."];
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

+ (id)cloneFromURL:(NSURL *)originURL toWorkingDirectory:(NSURL *)workdirURL barely:(BOOL)barely withCheckout:(BOOL)withCheckout error:(NSError **)error transferProgressBlock:(void (^)(const git_transfer_progress *))transferProgressBlock checkoutProgressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))checkoutProgressBlock asUser:(NSString*)username withPassword:(NSString*)password {
	
	git_clone_options cloneOptions = GIT_CLONE_OPTIONS_INIT;
	if (barely) {
		cloneOptions.bare = 1;
	}
	
	if (withCheckout) {
		git_checkout_opts checkoutOptions = GIT_CHECKOUT_OPTS_INIT;
		checkoutOptions.checkout_strategy = GIT_CHECKOUT_SAFE_CREATE;
		checkoutOptions.progress_cb = checkoutProgressCallback;
		checkoutOptions.progress_payload = (__bridge void *)checkoutProgressBlock;
		cloneOptions.checkout_opts = checkoutOptions;
	}
	
	cloneOptions.fetch_progress_cb = transferProgressCallback;
	cloneOptions.fetch_progress_payload = (__bridge void *)transferProgressBlock;
	
	if (([username length] > 0)&&([password length] > 0)) {
		// Auth might fail in case of redirects.
		[GTRepository cacheCredentialsForCallBack:[originURL absoluteString] username:username password:password];
		cloneOptions.cred_acquire_cb = cred_acquire_cb;
	}
	
	const char *remoteURL = originURL.absoluteString.UTF8String;
	const char *workingDirectoryPath = workdirURL.path.UTF8String;
	git_repository *repository;
	int gitError = git_clone(&repository, remoteURL, workingDirectoryPath, &cloneOptions);
	
	[GTRepository forgetCredentialsForUrl:[originURL absoluteString]];
	
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to clone repository."];
		return nil;
	}
	
	return [[self alloc] initWithGitRepository:repository];
	
}

+ (id)cloneFromURL:(NSURL *)originURL toWorkingDirectory:(NSURL *)workdirURL barely:(BOOL)barely withCheckout:(BOOL)withCheckout error:(NSError **)error transferProgressBlock:(void (^)(const git_transfer_progress *))transferProgressBlock checkoutProgressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))checkoutProgressBlock {
	
	return [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL barely:barely withCheckout:withCheckout error:error transferProgressBlock:transferProgressBlock checkoutProgressBlock:checkoutProgressBlock asUser:nil withPassword:nil];
	
}

- (bool)fetchFromRemote:(NSString*)name transferProgressBlock:(void (^)(const git_transfer_progress *))transferProgressBlock error:(NSError **)error {
	
    return  [self fetchFromRemote:name transferProgressBlock:transferProgressBlock error:error asUser:nil withPassword:nil];
	
}

- (bool)fetchFromRemote:(NSString*)name transferProgressBlock:(void (^)(const git_transfer_progress *))transferProgressBlock error:(NSError **)error asUser:(NSString*)username withPassword:(NSString*)password {
	git_remote *remote = NULL;
	const char *cname;
	if (name) {
		cname = [name UTF8String];
	} else {
		cname = [@"origin" UTF8String];
	}
	
	int gitError = git_remote_load(&remote, self.git_repository, cname);
    if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to fetch."];
		return false;
	}
	
	NSString *_url = [NSString stringWithUTF8String:git_remote_url(remote)];
	if (([username length] > 0)&&([password length] > 0)) {
		// Auth might fail in case of redirects.
		[GTRepository cacheCredentialsForCallBack:_url username:username password:password];
		git_remote_set_cred_acquire_cb(remote, cred_acquire_cb, NULL);
	}
	
	gitError = git_remote_connect(remote, GIT_DIRECTION_FETCH);
    if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to fetch."];
		return false;
	}
	
	gitError = git_remote_download(remote, transferProgressCallback, (__bridge void *)transferProgressBlock);
    if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to fetch."];
		return false;
	}

	gitError = git_remote_update_tips(remote);
    if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to fetch."];
		return false;
	}
	
    git_remote_disconnect(remote);
	git_remote_free(remote);
	
	return true;
}

+ (NSString *)hash:(NSString *)data objectType:(GTObjectType)type error:(NSError **)error {
	git_oid oid;

	int gitError = git_odb_hash(&oid, [data UTF8String], [data length], (git_otype) type);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to get hash for object."];
		return nil;
	}

	return [NSString git_stringWithOid:&oid];
}

- (GTObject *)lookupObjectByOid:(git_oid *)oid objectType:(GTObjectType)type error:(NSError **)error {
	git_object *obj;

	int gitError = git_object_lookup(&obj, self.git_repository, oid, (git_otype) type);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to lookup object in repository."];
		return nil;
	}

    return [GTObject objectWithObj:obj inRepository:self];
}

- (GTObject *)lookupObjectByOid:(git_oid *)oid error:(NSError **)error {
	return [self lookupObjectByOid:oid objectType:GTObjectTypeAny error:error];
}

- (GTObject *)lookupObjectBySha:(NSString *)sha objectType:(GTObjectType)type error:(NSError **)error {
	git_oid oid;

	int gitError = git_oid_fromstr(&oid, [sha UTF8String]);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorForMkStr:gitError];
		return nil;
	}

	return [self lookupObjectByOid:&oid objectType:type error:error];
}

- (GTObject *)lookupObjectBySha:(NSString *)sha error:(NSError **)error {
	return [self lookupObjectBySha:sha objectType:GTObjectTypeAny error:error];
}

- (GTObject *)lookupObjectByRefspec:(NSString *)spec error:(NSError **)error {
	git_object *obj;
	int gitError = git_revparse_single(&obj, self.git_repository, spec.UTF8String);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to lookup object by refspec."];
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
	GTReference *headSymRef = [GTReference referenceByLookingUpReferencedNamed:@"HEAD" inRepository:self error:error];
	if (headSymRef == nil) return nil;

	return [GTReference referenceByResolvingSymbolicReference:headSymRef error:error];
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

- (NSUInteger)numberOfCommitsInCurrentBranch:(NSError **)error {
	GTBranch *currentBranch = [self currentBranchWithError:error];
	if (currentBranch == nil) return NSNotFound;

	return [currentBranch numberOfCommitsWithError:error];
}

- (GTBranch *)createBranchNamed:(NSString *)name fromReference:(GTReference *)ref error:(NSError **)error {
	// make sure the ref is up to date before we branch off it, otherwise we could branch off an older sha
	ref = [ref reloadedReferenceWithError:error];
	if (ref == nil) return nil;

	GTReference *newRef = [GTReference referenceByCreatingReferenceNamed:[NSString stringWithFormat:@"%@%@", [GTBranch localNamePrefix], name] fromReferenceTarget:ref.target inRepository:self error:error];
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
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to list all references."];
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

- (BOOL)isHeadDetached {
	return (BOOL) git_repository_head_detached(self.git_repository);
}

- (BOOL)resetToCommit:(GTCommit *)commit withResetType:(GTRepositoryResetType)resetType error:(NSError **)error {
    NSParameterAssert(commit != nil);
    
    int result = git_reset(self.git_repository, commit.git_object, (git_reset_t)resetType);
    if (result == GIT_OK) return YES;
    
    if (error != NULL) *error = [NSError git_errorFor:result withAdditionalDescription:@"Failed to reset repository."];
    
    return NO;
}

- (NSString *)preparedMessageWithError:(NSError **)error {
	void (^setErrorFromCode)(int) = ^(int errorCode) {
		if (errorCode == 0 || errorCode == GIT_ENOTFOUND) {
			// Not an error.
			return;
		}

		if (error != NULL) {
			*error = [NSError git_errorFor:errorCode withAdditionalDescription:@"Failed to read prepared message."];
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
		if (error != NULL) *error = [NSError git_errorFor:errorCode withAdditionalDescription:@"Failed to find merge base between commits."];
		return nil;
	}
	
	return (id)[self lookupObjectByOid:&mergeBase objectType:GTObjectTypeCommit error:error];
}

- (GTObjectDatabase *)objectDatabaseWithError:(NSError **)error {
	return [[GTObjectDatabase alloc] initWithRepository:self error:error];
}

- (GTConfiguration *)configurationWithError:(NSError **)error {
	git_config *config = NULL;
	int gitError = git_repository_config(&config, self.git_repository);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Faied to get config for repository."];
		return nil;
	}

	return [[GTConfiguration alloc] initWithGitConfig:config repository:self];
}

- (GTIndex *)indexWithError:(NSError **)error {
	git_index *index = NULL;
	int gitError = git_repository_index(&index, self.git_repository);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to get index for repository."];
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
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to reload submodules."];
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
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to look up specified submodule."];
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

@end
