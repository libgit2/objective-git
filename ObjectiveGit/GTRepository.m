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

#import "GTBlob.h"
#import "GTBranch.h"
#import "GTCheckoutOptions.h"
#import "GTCommit.h"
#import "GTConfiguration+Private.h"
#import "GTConfiguration.h"
#import "GTCredential+Private.h"
#import "GTCredential.h"
#import "GTDiffFile.h"
#import "GTEnumerator.h"
#import "GTFilterList.h"
#import "GTIndex.h"
#import "GTOID.h"
#import "GTObject.h"
#import "GTObjectDatabase.h"
#import "GTSignature.h"
#import "GTSubmodule.h"
#import "GTTag.h"
#import "GTTree.h"
#import "GTTreeBuilder.h"
#import "NSArray+StringArray.h"
#import "NSError+Git.h"
#import "NSString+Git.h"
#import "GTRepository+References.h"
#import "GTNote.h"

#import "EXTScope.h"

#import "git2.h"

NSString * const GTRepositoryCloneOptionsBare = @"GTRepositoryCloneOptionsBare";
NSString * const GTRepositoryCloneOptionsPerformCheckout = @"GTRepositoryCloneOptionsPerformCheckout";
NSString * const GTRepositoryCloneOptionsCheckoutOptions = @"GTRepositoryCloneOptionsCheckoutOptions";
NSString * const GTRepositoryCloneOptionsTransportFlags = @"GTRepositoryCloneOptionsTransportFlags";
NSString * const GTRepositoryCloneOptionsCredentialProvider = @"GTRepositoryCloneOptionsCredentialProvider";
NSString * const GTRepositoryCloneOptionsCloneLocal = @"GTRepositoryCloneOptionsCloneLocal";
NSString * const GTRepositoryCloneOptionsServerCertificateURL = @"GTRepositoryCloneOptionsServerCertificateURL";
NSString * const GTRepositoryInitOptionsFlags = @"GTRepositoryInitOptionsFlags";
NSString * const GTRepositoryInitOptionsMode = @"GTRepositoryInitOptionsMode";
NSString * const GTRepositoryInitOptionsWorkingDirectoryPath = @"GTRepositoryInitOptionsWorkingDirectoryPath";
NSString * const GTRepositoryInitOptionsDescription = @"GTRepositoryInitOptionsDescription";
NSString * const GTRepositoryInitOptionsTemplateURL = @"GTRepositoryInitOptionsTemplateURL";
NSString * const GTRepositoryInitOptionsInitialHEAD = @"GTRepositoryInitOptionsInitialHEAD";
NSString * const GTRepositoryInitOptionsOriginURLString = @"GTRepositoryInitOptionsOriginURLString";

typedef void (^GTRepositorySubmoduleEnumerationBlock)(GTSubmodule *submodule, NSError *error, BOOL *stop);
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
	if (self.isBare) {
		return [NSString stringWithFormat:@"<%@: %p> (bare) gitDirectoryURL: %@", self.class, self, self.gitDirectoryURL];
	}
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

+ (instancetype)initializeEmptyRepositoryAtFileURL:(NSURL *)localFileURL options:(NSDictionary *)optionsDict error:(NSError **)error {
	if (!localFileURL.isFileURL || localFileURL.path == nil) {
		if (error != NULL) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnsupportedSchemeError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid file path URL to initialize repository.", @"") }];
		return nil;
	}

	git_repository_init_options options = GIT_REPOSITORY_INIT_OPTIONS_INIT;
	options.mode = (uint32_t)
	[optionsDict[GTRepositoryInitOptionsMode] unsignedIntegerValue];
	options.workdir_path = [optionsDict[GTRepositoryInitOptionsWorkingDirectoryPath] UTF8String];
	options.description = [optionsDict[GTRepositoryInitOptionsDescription] UTF8String];
	options.template_path = [optionsDict[GTRepositoryInitOptionsTemplateURL] path].UTF8String;
	options.initial_head = [optionsDict[GTRepositoryInitOptionsInitialHEAD] UTF8String];
	options.origin_url = [optionsDict[GTRepositoryInitOptionsOriginURLString] UTF8String];

	// This default mirrors git_repository_init().
	NSNumber *flags = optionsDict[GTRepositoryInitOptionsFlags];
	options.flags = (flags == nil ? GIT_REPOSITORY_INIT_MKPATH : (uint32_t)flags.unsignedIntegerValue);

	const char *path = localFileURL.path.fileSystemRepresentation;
	git_repository *repository = NULL;
	int gitError = git_repository_init_ext(&repository, path, &options);
	if (gitError != GIT_OK || repository == NULL) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to initialize empty repository at URL %@.", localFileURL];
		return nil;
	}

	return [[self alloc] initWithGitRepository:repository];
}

+ (instancetype)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error {
	return [[self alloc] initWithURL:localFileURL error:error];
}

- (instancetype)init {
	NSAssert(NO, @"Call to an unavailable initializer.");
	return nil;
}

- (instancetype)initWithGitRepository:(git_repository *)repository {
	NSParameterAssert(repository != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_repository = repository;

	return self;
}

- (instancetype)initWithURL:(NSURL *)localFileURL error:(NSError **)error {
	if (![localFileURL isFileURL] || localFileURL.path == nil) {
		if (error != NULL) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnsupportedSchemeError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid file path URL to open.", @"") }];
		return nil;
	}

	git_repository *r;
	int gitError = git_repository_open(&r, localFileURL.path.fileSystemRepresentation);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to open repository at URL %@.", localFileURL];
		return nil;
	}

	return [self initWithGitRepository:r];
}

- (instancetype)initWithURL:(NSURL *)localFileURL flags:(NSInteger)flags ceilingDirs:(NSArray<NSURL *> *)ceilingDirURLs error:(NSError **)error {
	if (!localFileURL.isFileURL || localFileURL.path == nil) {
		if (error != NULL) *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnsupportedSchemeError userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"Invalid file path URL to open.", @"") }];
		return nil;
	}

	// Concatenate URL paths.
	NSMutableString *ceilingDirsString;
	if (ceilingDirURLs.count > 0) {
		ceilingDirsString = [[NSMutableString alloc] init];
		[ceilingDirURLs enumerateObjectsUsingBlock:^(NSURL * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
			if (idx < ceilingDirURLs.count - 1) {
				[ceilingDirsString appendString:[NSString stringWithFormat:@"%@%c", url.path, GIT_PATH_LIST_SEPARATOR]];
			} else {
				[ceilingDirsString appendString:url.path];
			}
		}];
	}

	git_repository *r;
	int gitError = git_repository_open_ext(&r, localFileURL.path.fileSystemRepresentation, (unsigned int)flags, ceilingDirsString.fileSystemRepresentation);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to open repository at URL %@.", localFileURL];
		return nil;
	}

	return [self initWithGitRepository:r];
}


typedef void(^GTTransferProgressBlock)(const git_transfer_progress *progress, BOOL *stop);

static int transferProgressCallback(const git_transfer_progress *progress, void *payload) {
	if (payload == NULL) return 0;
	struct GTClonePayload *pld = payload;
	if (pld->transferProgressBlock == NULL) return 0;

	BOOL stop = NO;
	pld->transferProgressBlock(progress, &stop);
	return (stop ? GIT_EUSER : 0);
}

struct GTClonePayload {
	GTCredentialAcquireCallbackInfo credProvider;
	__unsafe_unretained GTTransferProgressBlock transferProgressBlock;
};

static int remoteCreate(git_remote **remote, git_repository *repo, const char *name, const char *url, void *payload)
{
	int error;
	if ((error = git_remote_create(remote, repo, name, url)) < 0)
		return error;

	return GIT_OK;
}

struct GTRemoteCreatePayload {
	git_remote_callbacks remoteCallbacks;
};

+ (instancetype _Nullable)cloneFromURL:(NSURL *)originURL toWorkingDirectory:(NSURL *)workdirURL options:(NSDictionary * _Nullable)options error:(NSError **)error transferProgressBlock:(void (^ _Nullable)(const git_transfer_progress *, BOOL *stop))transferProgressBlock {

	git_clone_options cloneOptions = GIT_CLONE_OPTIONS_INIT;

	NSNumber *bare = options[GTRepositoryCloneOptionsBare];
	cloneOptions.bare = (bare == nil ? 0 : bare.boolValue);

	NSNumber *checkout = options[GTRepositoryCloneOptionsPerformCheckout];
	BOOL doCheckout = (checkout != nil ? [checkout boolValue] : YES);

	GTCheckoutOptions *checkoutOptions = options[GTRepositoryCloneOptionsCheckoutOptions];
	if (checkoutOptions == nil && doCheckout) {
		checkoutOptions = [GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategySafe];
	}

	if (checkoutOptions != nil) {
		cloneOptions.checkout_opts = *(checkoutOptions.git_checkoutOptions);
	}

	GTCredentialProvider *provider = options[GTRepositoryCloneOptionsCredentialProvider];
	struct GTClonePayload payload = {
		.credProvider = {provider},
	};

	git_fetch_options fetchOptions = GIT_FETCH_OPTIONS_INIT;
	fetchOptions.callbacks.version = GIT_REMOTE_CALLBACKS_VERSION;

	if (provider) {
		fetchOptions.callbacks.credentials = GTCredentialAcquireCallback;
	}

	payload.transferProgressBlock = transferProgressBlock;

	fetchOptions.callbacks.transfer_progress = transferProgressCallback;
	fetchOptions.callbacks.payload = &payload;
	cloneOptions.fetch_opts = fetchOptions;
	cloneOptions.remote_cb = remoteCreate;

	BOOL localClone = [options[GTRepositoryCloneOptionsCloneLocal] boolValue];
	if (localClone) {
		cloneOptions.local = GIT_CLONE_NO_LOCAL;
	}

	NSURL *serverCertificateURL = options[GTRepositoryCloneOptionsServerCertificateURL];
	if (serverCertificateURL) {
		int gitError = git_libgit2_opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, serverCertificateURL.fileSystemRepresentation, NULL);
		if (gitError < GIT_OK) {
			if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to configure the server certificate at %@", serverCertificateURL];
			return nil;
		}
	}

	// If our originURL is local, convert to a path before handing down.
	const char *remoteURL = NULL;
	if (originURL.isFileURL) {
		remoteURL = originURL.path.fileSystemRepresentation;
	} else {
		remoteURL = originURL.absoluteString.UTF8String;
	}
	const char *workingDirectoryPath = workdirURL.path.fileSystemRepresentation;
	git_repository *repository;
	int gitError = git_clone(&repository, remoteURL, workingDirectoryPath, &cloneOptions);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to clone repository from %@ to %@", originURL, workdirURL];
		return nil;
	}

	return [[self alloc] initWithGitRepository:repository];
}

- (id)lookUpObjectByGitOid:(const git_oid *)oid objectType:(GTObjectType)type error:(NSError **)error {
	git_object *obj;

	int gitError = git_object_lookup(&obj, self.git_repository, oid, (git_otype)type);
	if (gitError < GIT_OK) {
		if (error != NULL) {
			char oid_str[GIT_OID_HEXSZ+1];
			git_oid_tostr(oid_str, sizeof(oid_str), oid);
			*error = [NSError git_errorFor:gitError description:@"Failed to lookup object" userInfo:@{GTGitErrorOID: [GTOID oidWithGitOid:oid]} failureReason:@"The object %s couldn't be found in the repository.", oid_str];
		}
		return nil;
	}

    return [GTObject objectWithObj:obj inRepository:self];
}

- (id)lookUpObjectByGitOid:(const git_oid *)oid error:(NSError **)error {
	return [self lookUpObjectByGitOid:oid objectType:GTObjectTypeAny error:error];
}

- (id)lookUpObjectByOID:(GTOID *)oid objectType:(GTObjectType)type error:(NSError **)error {
	return [self lookUpObjectByGitOid:oid.git_oid objectType:type error:error];
}

- (id)lookUpObjectByOID:(GTOID *)oid error:(NSError **)error {
	return [self lookUpObjectByOID:oid objectType:GTObjectTypeAny error:error];
}

- (id)lookUpObjectBySHA:(NSString *)sha objectType:(GTObjectType)type error:(NSError **)error {
	GTOID *oid = [[GTOID alloc] initWithSHA:sha error:error];
	if (!oid) return nil;

	return [self lookUpObjectByOID:oid objectType:type error:error];
}

- (id)lookUpObjectBySHA:(NSString *)sha error:(NSError **)error {
	return [self lookUpObjectBySHA:sha objectType:GTObjectTypeAny error:error];
}

- (id)lookUpObjectByRevParse:(NSString *)spec error:(NSError **)error {
	git_object *obj;
	int gitError = git_revparse_single(&obj, self.git_repository, spec.UTF8String);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Revision specifier lookup failed." failureReason:@"The revision specifier \"%@\" couldn't be parsed.", spec];
		return nil;
	}
	return [GTObject objectWithObj:obj inRepository:self];
}

- (GTBranch *)lookUpBranchWithName:(NSString *)branchName type:(GTBranchType)branchType success:(BOOL *)success error:(NSError **)error {
	NSParameterAssert(branchName != nil);

	git_reference *ref = NULL;
	int gitError = git_branch_lookup(&ref, self.git_repository, branchName.UTF8String, (git_branch_t)branchType);
	if (gitError < GIT_OK && gitError != GIT_ENOTFOUND) {
		if (success != NULL) *success = NO;
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Branch lookup failed"];

		return nil;
	}

	if (success != NULL) *success = YES;
	if (ref == NULL) return nil;

	GTReference *gtRef = [[GTReference alloc] initWithGitReference:ref repository:self];
	return [[GTBranch alloc] initWithReference:gtRef repository:self];
}

- (GTReference *)headReferenceWithError:(NSError **)error {
	git_reference *headRef;
	int gitError = git_repository_head(&headRef, self.git_repository);
	if (gitError != GIT_OK) {
		NSString *unborn = @"";
		if (gitError == GIT_EUNBORNBRANCH) {
			unborn = @" (unborn)";
		}
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get HEAD%@", unborn];
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
	for (NSString *refName in references) {
		if (![refName hasPrefix:prefix]) continue;

		GTReference *ref = [self lookUpReferenceWithName:refName error:error];
		if (ref == nil) continue;

		GTBranch *branch = [[GTBranch alloc] initWithReference:ref repository:self];
		if (branch == nil) continue;

		[branches addObject:branch];
	}

	return branches;
}

- (NSArray *)branches:(NSError **)error {
	NSArray *localBranches = [self localBranchesWithError:error];
	if (localBranches == nil) return nil;

	NSMutableArray *remoteBranches = [[self remoteBranchesWithError:error] mutableCopy];
	if (remoteBranches == nil) return nil;

	NSMutableArray *branches = [NSMutableArray array];
	for (GTBranch *branch in localBranches) {
		GTBranch *trackingBranch = [branch trackingBranchWithError:NULL success:NULL];
		if (trackingBranch != nil) [remoteBranches removeObject:trackingBranch];
		[branches addObject:branch];
	}

	[branches addObjectsFromArray:remoteBranches];

	return branches;
}

- (NSArray *)remoteNamesWithError:(NSError **)error {
	git_strarray array;
	int gitError = git_remote_list(&array, self.git_repository);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to list all remotes."];
		return nil;
	}

	NSArray *remoteNames = [NSArray git_arrayWithStrarray:array];

	git_strarray_free(&array);

	return remoteNames;
}

struct GTRepositoryTagEnumerationInfo {
	__unsafe_unretained GTRepository *myself;
	__unsafe_unretained GTRepositoryTagEnumerationBlock block;
};

static int GTRepositoryForeachTagCallback(const char *name, git_oid *oid, void *payload) {
	struct GTRepositoryTagEnumerationInfo *info = payload;
	GTTag *tag = (GTTag *)[info->myself lookUpObjectByGitOid:oid objectType:GTObjectTypeTag error:NULL];

	BOOL stop = NO;
	if (tag != nil) {
		info->block(tag, &stop);
	}

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

- (GTReference *)createReferenceNamed:(NSString *)name fromOID:(GTOID *)targetOID message:(NSString *)message error:(NSError **)error {
	NSParameterAssert(name != nil);
	NSParameterAssert(targetOID != nil);

	git_reference *ref;
	int gitError = git_reference_create(&ref, self.git_repository, name.UTF8String, targetOID.git_oid, 0, message.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create direct reference to %@", targetOID];
		return nil;
	}

	return [[GTReference alloc] initWithGitReference:ref repository:self];
}

- (GTReference *)createReferenceNamed:(NSString *)name fromReference:(GTReference *)targetRef message:(NSString *)message error:(NSError **)error {
	NSParameterAssert(name != nil);
	NSParameterAssert(targetRef != nil);
	NSParameterAssert(targetRef.name != nil);

	git_reference *ref;
	int gitError = git_reference_symbolic_create(&ref, self.git_repository, name.UTF8String, targetRef.name.UTF8String, 0, message.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create symbolic reference to %@", targetRef];
		return nil;
	}

	return [[GTReference alloc] initWithGitReference:ref repository:self];
}

- (GTBranch *)createBranchNamed:(NSString *)name fromOID:(GTOID *)targetOID message:(NSString *)message error:(NSError **)error {
	NSParameterAssert(name != nil);
	NSParameterAssert(targetOID != nil);

	GTReference *newRef = [self createReferenceNamed:[GTBranch.localNamePrefix stringByAppendingString:name] fromOID:targetOID message:message error:error];
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

	NSArray *referenceNames = [NSArray git_arrayWithStrarray:array];

	git_strarray_free(&array);

	return referenceNames;
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
	return (BOOL)git_repository_is_bare(self.git_repository);
}

- (BOOL)isHEADDetached {
	return (BOOL)git_repository_head_detached(self.git_repository);
}

- (BOOL)isHEADUnborn {
	return (BOOL)git_repository_head_unborn(self.git_repository);
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

	git_buf msg = { NULL };
	int errorCode = git_repository_message(&msg, self.git_repository);
	if (errorCode != GIT_OK) {
		setErrorFromCode(errorCode);
		git_buf_free(&msg);
		return nil;
	}

	NSString *message = [[NSString alloc] initWithBytes:msg.ptr length:msg.size encoding:NSUTF8StringEncoding];

	git_buf_free(&msg);

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

	return [self lookUpObjectByGitOid:&mergeBase objectType:GTObjectTypeCommit error:error];
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
		return nil;
	}

	return [[GTIndex alloc] initWithGitIndex:index repository:self];
}

#pragma mark Submodules

static int submoduleEnumerationCallback(git_submodule *git_submodule, const char *name, void *payload) {
	GTRepositorySubmoduleEnumerationInfo *info = payload;

	NSError *error;
	// Use -submoduleWithName:error: so that we get a git_submodule that we own.
	GTSubmodule *submodule = [info->parentRepository submoduleWithName:@(name) error:&error];

	BOOL stop = NO;
	info->block(submodule, error, &stop);
	if (stop) return 1;

	if (info->recursive) {
		[[submodule submoduleRepository:NULL] enumerateSubmodulesRecursively:YES usingBlock:info->block];
	}

	return 0;
}

- (void)enumerateSubmodulesRecursively:(BOOL)recursive usingBlock:(void (^)(GTSubmodule *submodule, NSError *error, BOOL *stop))block {
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

+ (NSString *)defaultUserName {
	NSString *name = NSFullUserName();
	if (name.length == 0) name = NSUserName();
	if (name.length == 0) name = @"nobody";
	return name;
}

+ (NSString *)defaultEmail {
	NSString *username = NSUserName();
	if (username.length == 0) username = @"nobody";
	NSString *domain = NSProcessInfo.processInfo.hostName ?: @"nowhere.local";
	return [NSString stringWithFormat:@"%@@%@", username, domain];
}

- (GTSignature *)userSignatureForNow {
	GTConfiguration *configuration = [self configurationWithError:NULL];
	NSString *name = [configuration stringForKey:@"user.name"];
	if (name.length == 0) name = self.class.defaultUserName;

	NSString *email = [configuration stringForKey:@"user.email"];
	if (email.length == 0) email = self.class.defaultEmail;

	NSDate *now = [NSDate date];
	GTSignature *signature = [[GTSignature alloc] initWithName:name email:email time:now];
	if (signature != nil) return signature;

	return [[GTSignature alloc] initWithName:self.class.defaultUserName email:self.class.defaultEmail time:now];
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
	return oid ? [self lookUpObjectByOID:oid objectType:GTObjectTypeTag error:error] : nil;
}

#pragma mark Checkout

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

- (BOOL)performCheckout:(GTObject *)target options:(GTCheckoutOptions * _Nullable)options error:(NSError **)error {
	int gitError = git_checkout_tree(self.git_repository, target.git_object, options.git_checkoutOptions);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to checkout tree."];
	}
	return gitError == GIT_OK;
}

- (BOOL)checkoutCommit:(GTCommit *)targetCommit options:(GTCheckoutOptions *)options error:(NSError **)error {
	BOOL success = [self performCheckout:targetCommit options:options error:error];
	if (success == NO) return NO;
	return [self moveHEADToCommit:targetCommit error:error];
}

- (BOOL)checkoutReference:(GTReference *)targetReference options:(GTCheckoutOptions *)options error:(NSError **)error {
	GTOID *targetOID = [targetReference targetOID];
	GTObject *target = [self lookUpObjectByOID:targetOID error:error];
	if (target == nil) return NO;
	BOOL success = [self performCheckout:target options:options error:error];
	if (success == NO) return NO;
	return [self moveHEADToReference:targetReference error:error];
}

- (BOOL)checkoutTree:(GTTree *)targetTree options:(GTCheckoutOptions * _Nullable)options error:(NSError **)error {
	return [self performCheckout:targetTree options:options error:error];
}

- (BOOL)checkoutIndex:(GTIndex *)index options:(GTCheckoutOptions *)options error:(NSError **)error {
	int gitError = git_checkout_index(self.git_repository, index.git_index, options.git_checkoutOptions);
	if (gitError < GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to checkout index."];
		return NO;
	}
	return YES;
}

- (void)flushAttributesCache {
	git_attr_cache_flush(self.git_repository);
}

- (GTFilterList *)filterListWithPath:(NSString *)path blob:(GTBlob *)blob mode:(GTFilterSourceMode)mode options:(GTFilterListOptions)options success:(BOOL *)success error:(NSError **)error {
	NSParameterAssert(path != nil);

	git_filter_list *list = NULL;
	int gitError = git_filter_list_load(&list, self.git_repository, blob.git_blob, path.UTF8String, (git_filter_mode_t)mode, options);
	if (gitError != GIT_OK) {
		if (success != NULL) *success = NO;
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to load filter list for %@", path];

		return nil;
	}

	if (success != NULL) *success = YES;
	if (list == NULL) {
		return nil;
	} else {
		return [[GTFilterList alloc] initWithGitFilterList:list];
	}
}

- (BOOL)calculateAhead:(size_t *)ahead behind:(size_t *)behind ofOID:(GTOID *)headOID relativeToOID:(GTOID *)baseOID error:(NSError **)error {
	NSParameterAssert(headOID != nil);
	NSParameterAssert(baseOID != nil);

	int errorCode = git_graph_ahead_behind(ahead, behind, self.git_repository, headOID.git_oid, baseOID.git_oid);
	if (errorCode != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:errorCode description:@"Failed to calculate ahead/behind count of %@ relative to %@", headOID, baseOID];

		return NO;
	}

	return YES;
}

- (GTEnumerator *)enumeratorForUniqueCommitsFromOID:(GTOID *)fromOID relativeToOID:(GTOID *)relativeOID error:(NSError **)error {
	NSParameterAssert(fromOID != nil);
	NSParameterAssert(relativeOID != nil);

	GTEnumerator *enumerator = [[GTEnumerator alloc] initWithRepository:self error:error];
	if (enumerator == nil) return nil;

	BOOL success = [enumerator pushSHA:fromOID.SHA error:error];
	if (!success) return nil;

	success = [enumerator hideSHA:relativeOID.SHA error:error];
	if (!success) return nil;

	return enumerator;
}

- (BOOL)calculateState:(GTRepositoryStateType *)state withError:(NSError **)error {
	NSParameterAssert(state != NULL);

	int result = git_repository_state(self.git_repository);
	if (result < 0) {
		if (error != NULL) *error = [NSError git_errorFor:result description:@"Failed to calculate repository state"];
		return NO;
	}

	*state = result;
	return YES;
}

- (BOOL)cleanupStateWithError:(NSError **)error {
	int errorCode = git_repository_state_cleanup(self.git_repository);
	if (errorCode != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:errorCode description:@"Failed to clean up repository state"];
	}
	return YES;
}

#pragma mark Notes

- (GTNote *)createNote:(NSString *)note target:(GTObject *)theTarget referenceName:(NSString *)referenceName author:(GTSignature *)author committer:(GTSignature *)committer overwriteIfExists:(BOOL)overwrite error:(NSError **)error {
	git_oid oid;

	int gitError = git_note_create(&oid, self.git_repository, referenceName.UTF8String, author.git_signature, committer.git_signature, theTarget.OID.git_oid, [note UTF8String], overwrite ? 1 : 0);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to create a note in repository"];

		return nil;
	}

	return [[GTNote alloc] initWithTargetOID:theTarget.OID repository:self referenceName:referenceName error:error];
}

- (BOOL)removeNoteFromObject:(GTObject *)parentObject referenceName:(NSString *)referenceName author:(GTSignature *)author committer:(GTSignature *)committer error:(NSError **)error {
	int gitError = git_note_remove(self.git_repository, referenceName.UTF8String, author.git_signature, committer.git_signature, parentObject.OID.git_oid);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to delete note from %@", parentObject];
		return NO;
	}

	return YES;
}

- (BOOL)enumerateNotesWithReferenceName:(NSString *)referenceName error:(NSError **)error usingBlock:(void (^)(GTNote *note, GTObject *object, NSError *error, BOOL *stop))block {
	git_note_iterator *iter = NULL;

	int gitError = git_note_iterator_new(&iter, self.git_repository, referenceName.UTF8String);

	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to enumerate notes"];
		return NO;
	}

	@onExit {
		git_note_iterator_free(iter);
	};

	git_oid note_id;
	git_oid object_id;
	BOOL success = YES;
	int iterError = GIT_OK;

	while ((iterError = git_note_next(&note_id, &object_id, iter)) == GIT_OK) {
		NSError *lookupErr = nil;

		GTNote *note = [[GTNote alloc] initWithTargetOID:[GTOID oidWithGitOid:&object_id] repository:self referenceName:referenceName error:&lookupErr];
		GTObject *obj = nil;

		if (note != nil) obj = [self lookUpObjectByGitOid:&object_id error:&lookupErr];

		BOOL stop = NO;
		block(note, obj, lookupErr, &stop);
		if (stop) {
			break;
		}
	}

	if (iterError != GIT_OK && iterError != GIT_ITEROVER) {
		if (error != NULL) *error = [NSError git_errorFor:iterError description:@"Iterator error"];
	}

	return success;
}

@end
