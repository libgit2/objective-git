//
//  GTRepository+RemoteOperations.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 18/11/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTRepository+RemoteOperations.h"

#import "EXTScope.h"
#import "GTCredential.h"
#import "GTCredential+Private.h"
#import "GTFetchHeadEntry.h"
#import "GTOID.h"
#import "GTRemote.h"
#import "GTSignature.h"
#import "NSArray+StringArray.h"
#import "NSError+Git.h"
#import "GTRepository+References.h"
#import "GTNote.h"

#import "git2/errors.h"
#import "git2/remote.h"
#import "git2/notes.h"
#import "git2/buffer.h"

NSString *const GTRepositoryRemoteOptionsCredentialProvider = @"GTRepositoryRemoteOptionsCredentialProvider";
NSString *const GTRepositoryRemoteOptionsFetchPrune = @"GTRepositoryRemoteOptionsFetchPrune";
NSString *const GTRepositoryRemoteOptionsDownloadTags = @"GTRepositoryRemoteOptionsDownloadTags";
NSString *const GTRepositoryRemoteOptionsPushNotes = @"GTRepositoryRemoteOptionsPushNotes";

typedef void (^GTRemoteFetchTransferProgressBlock)(const git_transfer_progress *stats, BOOL *stop);
typedef void (^GTRemotePushTransferProgressBlock)(unsigned int current, unsigned int total, size_t bytes, BOOL *stop);

@implementation GTRepository (RemoteOperations)

#pragma mark -
#pragma mark Common Remote code

typedef struct {
	GTCredentialAcquireCallbackInfo credProvider;
	__unsafe_unretained GTRemoteFetchTransferProgressBlock fetchProgressBlock;
	__unsafe_unretained GTRemotePushTransferProgressBlock pushProgressBlock;
	git_direction direction;
} GTRemoteConnectionInfo;

int GTRemoteFetchTransferProgressCallback(const git_transfer_progress *stats, void *payload) {
	GTRemoteConnectionInfo *info = payload;
	BOOL stop = NO;

	if (info->fetchProgressBlock != nil) {
		info->fetchProgressBlock(stats, &stop);
	}

	return (stop == YES ? GIT_EUSER : 0);
}

int GTRemotePushTransferProgressCallback(unsigned int current, unsigned int total, size_t bytes, void *payload) {
	GTRemoteConnectionInfo *pushPayload = payload;

	BOOL stop = NO;
	if (pushPayload->pushProgressBlock) {
		pushPayload->pushProgressBlock(current, total, bytes, &stop);
	}

	return (stop == YES ? GIT_EUSER : 0);
}

#pragma mark - Fetch

- (BOOL)fetchRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemoteFetchTransferProgressBlock)progressBlock {

	GTCredentialProvider *credProvider = options[GTRepositoryRemoteOptionsCredentialProvider];
	GTRemoteConnectionInfo connectionInfo = {
		.credProvider = {credProvider},
		.direction = GIT_DIRECTION_FETCH,
		.fetchProgressBlock = progressBlock,
	};
	git_remote_callbacks remote_callbacks = {
		.version = GIT_REMOTE_CALLBACKS_VERSION,
		.credentials = (credProvider != nil ? GTCredentialAcquireCallback : NULL),
		.transfer_progress = GTRemoteFetchTransferProgressCallback,
		.payload = &connectionInfo,
	};

	git_fetch_options fetchOptions = GIT_FETCH_OPTIONS_INIT;
	fetchOptions.callbacks = remote_callbacks;
	fetchOptions.prune = [options[GTRepositoryRemoteOptionsFetchPrune] unsignedIntValue];
	fetchOptions.download_tags = [options[GTRepositoryRemoteOptionsDownloadTags] unsignedIntValue];

	__block git_strarray refspecs;
	int gitError = git_remote_get_fetch_refspecs(&refspecs, remote.git_remote);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get fetch refspecs for remote"];
		return NO;
	}

	@onExit {
		git_strarray_free(&refspecs);
	};

	NSString *reflog_message = [NSString stringWithFormat:@"fetching remote %@", remote.name];

	gitError = git_remote_fetch(remote.git_remote, &refspecs, &fetchOptions, reflog_message.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to fetch from remote"];
		return NO;
	}

	return YES;
}

#pragma mark - Fetch Head Enumeration

typedef void (^GTRemoteEnumerateFetchHeadEntryBlock)(GTFetchHeadEntry *entry, BOOL *stop);

typedef struct {
	__unsafe_unretained GTRepository *repository;
	__unsafe_unretained GTRemoteEnumerateFetchHeadEntryBlock enumerationBlock;
} GTEnumerateHeadEntriesPayload;

int GTFetchHeadEntriesCallback(const char *ref_name, const char *remote_url, const git_oid *oid, unsigned int is_merge, void *payload) {
	GTEnumerateHeadEntriesPayload *entriesPayload = payload;

	GTRepository *repository = entriesPayload->repository;
	GTRemoteEnumerateFetchHeadEntryBlock enumerationBlock = entriesPayload->enumerationBlock;

	GTReference *reference = [repository lookUpReferenceWithName:@(ref_name) error:NULL];

	GTFetchHeadEntry *entry = [[GTFetchHeadEntry alloc] initWithReference:reference remoteURLString:@(remote_url) targetOID:[GTOID oidWithGitOid:oid] isMerge:(BOOL)is_merge];

	BOOL stop = NO;

	enumerationBlock(entry, &stop);

	return (stop == YES ? GIT_EUSER : 0);
}

- (BOOL)enumerateFetchHeadEntriesWithError:(NSError **)error usingBlock:(void (^)(GTFetchHeadEntry *fetchHeadEntry, BOOL *stop))block {
	NSParameterAssert(block != nil);
	
	GTEnumerateHeadEntriesPayload payload = {
		.repository = self,
		.enumerationBlock = block,
	};
	int gitError = git_repository_fetchhead_foreach(self.git_repository, GTFetchHeadEntriesCallback, &payload);

	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get fetchhead entries"];
		return NO;
	}
	
	return YES;
}

- (NSArray *)fetchHeadEntriesWithError:(NSError **)error {
	NSMutableArray *entries = [NSMutableArray array];
	
	[self enumerateFetchHeadEntriesWithError:error usingBlock:^(GTFetchHeadEntry *fetchHeadEntry, BOOL *stop) {
		[entries addObject:fetchHeadEntry];
		
		*stop = NO;
	}];
	
	return entries;
}

#pragma mark - Push (Public)

- (BOOL)pushBranch:(GTBranch *)branch toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemotePushTransferProgressBlock)progressBlock {
	NSParameterAssert(branch != nil);
	NSParameterAssert(remote != nil);

	return [self pushBranches:@[ branch ] toRemote:remote withOptions:options error:error progress:progressBlock];
}

- (BOOL)pushBranches:(NSArray *)branches toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemotePushTransferProgressBlock)progressBlock {
	NSParameterAssert(branches != nil);
	NSParameterAssert(branches.count != 0);
	NSParameterAssert(remote != nil);

	NSMutableArray *refspecs = nil;
	// Build refspecs for the passed in branches
	refspecs = [NSMutableArray arrayWithCapacity:branches.count];
	for (GTBranch *branch in branches) {
		// Default remote reference for when branch doesn't exist on remote - create with same short name
		NSString *remoteBranchReference = [NSString stringWithFormat:@"refs/heads/%@", branch.shortName];

		BOOL success = NO;
		GTBranch *trackingBranch = [branch trackingBranchWithError:error success:&success];

		if (success && trackingBranch != nil) {
			// Use remote branch short name from trackingBranch, which could be different
			// (e.g. refs/heads/master:refs/heads/my_master)
			remoteBranchReference = [NSString stringWithFormat:@"refs/heads/%@", trackingBranch.shortName];
		}

		[refspecs addObject:[NSString stringWithFormat:@"refs/heads/%@:%@", branch.shortName, remoteBranchReference]];
	}
	
	// Also push the notes reference(s), if needed.
	id pushNotesOption = options[GTRepositoryRemoteOptionsPushNotes];
	if (pushNotesOption != nil) {
		if ([pushNotesOption isKindOfClass:[NSNumber class]]) {		// Push notes is a bool, only push the default reference name if it's YES
			if ([(NSNumber *)pushNotesOption boolValue]) {
				NSString *notesReferenceName = [GTNote defaultReferenceNameForRepository:self error:nil];
				
				// Check whether the reference name exists for the repo, or our push will fail
				if (notesReferenceName != nil && [self lookUpReferenceWithName:notesReferenceName error:nil] != nil) {
					[refspecs addObject:[NSString stringWithFormat:@"%@:%@", notesReferenceName, notesReferenceName]];
				}
			}
		} else if ([pushNotesOption isKindOfClass:[NSArray class]]) {
			for (NSString *notesReferenceName in (NSArray *)pushNotesOption) {
				if ([notesReferenceName isKindOfClass:[NSString class]]) {		// Just a sanity check, we only accept NSStrings in the array
					// Check whether the reference name exists for the repo, or our push will fail
					if (notesReferenceName != nil && [self lookUpReferenceWithName:notesReferenceName error:nil] != nil) {
						[refspecs addObject:[NSString stringWithFormat:@"%@:%@", notesReferenceName, notesReferenceName]];
					}
				}
			}
		}
	}
	
	return [self pushRefspecs:refspecs toRemote:remote withOptions:options error:error progress:progressBlock];
}

- (BOOL)pushNotes:(NSString *)noteRef toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemotePushTransferProgressBlock)progressBlock {
	NSParameterAssert(remote != nil);

	if (noteRef == nil) {
		noteRef = [GTNote defaultReferenceNameForRepository:self error:error];
		
		if (noteRef == nil) return NO;
	}

	GTReference *notesReference = [self lookUpReferenceWithName:noteRef error:error];

	if (notesReference == nil) return NO;

	return [self pushRefspecs:@[[NSString stringWithFormat:@"%@:%@", noteRef, noteRef]] toRemote:remote withOptions:options error:error progress:progressBlock];
}

#pragma mark - Deletion (Public)
- (BOOL)deleteBranch:(GTBranch *)branch fromRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(branch != nil);
	NSParameterAssert(remote != nil);
		
	NSArray *refspecs = @[ [NSString stringWithFormat:@":refs/heads/%@", branch.shortName] ];
		
	return [self pushRefspecs:refspecs toRemote:remote withOptions:options error:error progress:nil];
}

#pragma mark - Push (Private)

- (BOOL)pushRefspecs:(NSArray *)refspecs toRemote:(GTRemote *)remote withOptions:(NSDictionary *)options error:(NSError **)error progress:(GTRemotePushTransferProgressBlock)progressBlock {

	int gitError;
	GTCredentialProvider *credProvider = options[GTRepositoryRemoteOptionsCredentialProvider];

	GTRemoteConnectionInfo connectionInfo = {
		.credProvider = { .credProvider = credProvider },
		.direction = GIT_DIRECTION_PUSH,
		.pushProgressBlock = progressBlock,
	};

	git_remote_callbacks remote_callbacks = GIT_REMOTE_CALLBACKS_INIT;
	remote_callbacks.credentials = (credProvider != nil ? GTCredentialAcquireCallback : NULL),
	remote_callbacks.push_transfer_progress = GTRemotePushTransferProgressCallback;
	remote_callbacks.payload = &connectionInfo,

	gitError = git_remote_connect(remote.git_remote, GIT_DIRECTION_PUSH, &remote_callbacks, NULL, NULL);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to connect remote"];
		return NO;
	}
	@onExit {
		git_remote_disconnect(remote.git_remote);
	};

	git_push_options push_options = GIT_PUSH_OPTIONS_INIT;

	gitError = git_push_init_options(&push_options, GIT_PUSH_OPTIONS_VERSION);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to init push options"];
		return NO;
	}

	push_options.callbacks = remote_callbacks;

	const git_strarray git_refspecs = refspecs.git_strarray;

	gitError = git_remote_upload(remote.git_remote, &git_refspecs, &push_options);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Push upload to remote failed"];
		return NO;
	}

	int update_fetchhead = 1;
	// Ignored for push
	git_remote_autotag_option_t download_tags = GIT_REMOTE_DOWNLOAD_TAGS_UNSPECIFIED;
	NSString *reflog_message = [NSString stringWithFormat:@"pushing remote %@", remote.name];

	gitError = git_remote_update_tips(remote.git_remote, &remote_callbacks, update_fetchhead, download_tags, reflog_message.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Update tips failed"];
		return NO;
	}

	return YES;
}

@end
