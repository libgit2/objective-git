//
//  GTRepository.h
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


#import "GTObject.h"
#import "GTEnumerator.h"
#import "GTReference.h"

@class GTBranch;
@class GTCommit;
@class GTConfiguration;
@class GTIndex;
@class GTObjectDatabase;
@class GTOdbObject;
@class GTSignature;
@class GTSubmodule;
@class GTDiffFile;
@class GTTag;

// Options returned from the enumerateFileStatusUsingBlock: function
enum {
	GTRepositoryFileStatusIndexNew = GIT_STATUS_INDEX_NEW,
	GTRepositoryFileStatusIndexModified = GIT_STATUS_INDEX_MODIFIED,
	GTRepositoryFileStatusIndexDeleted = GIT_STATUS_INDEX_DELETED,

	GTRepositoryFileStatusWorkingTreeNew = GIT_STATUS_WT_NEW,
	GTRepositoryFileStatusWorkingTreeModified = GIT_STATUS_WT_MODIFIED,
	GTRepositoryFileStatusWorkingTreeDeleted = GIT_STATUS_WT_DELETED,

	GTRepositoryFileStatusIgnored = GIT_STATUS_IGNORED
};

typedef unsigned int GTRepositoryFileStatus;

typedef enum {
	GTRepositoryResetTypeSoft = GIT_RESET_SOFT,
	GTRepositoryResetTypeMixed = GIT_RESET_MIXED,
	GTRepositoryResetTypeHard = GIT_RESET_HARD
} GTRepositoryResetType;

// Checkout strategies used by the various -checkout... methods
// See git_checkout_strategy_t
typedef enum {
	GTCheckoutStrategyNone = GIT_CHECKOUT_NONE,
	GTCheckoutStrategySafe = GIT_CHECKOUT_SAFE,
	GTCheckoutStrategySafeCreate = GIT_CHECKOUT_SAFE_CREATE,
	GTCheckoutStrategyForce = GIT_CHECKOUT_FORCE,
	GTCheckoutStrategyAllowConflicts = GIT_CHECKOUT_ALLOW_CONFLICTS,
	GTCheckoutStrategyRemoveUntracked = GIT_CHECKOUT_REMOVE_UNTRACKED,
	GTCheckoutStrategyRemoveIgnored = GIT_CHECKOUT_REMOVE_IGNORED,
	GTCheckoutStrategyUpdateOnly = GIT_CHECKOUT_UPDATE_ONLY,
	GTCheckoutStrategyDontUpdateIndex = GIT_CHECKOUT_DONT_UPDATE_INDEX,
	GTCheckoutStrategyNoRefresh = GIT_CHECKOUT_NO_REFRESH,
	GTCheckoutStrategyDisablePathspecMatch = GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH,
	GTCheckoutStrategySkipLockedDirectories = GIT_CHECKOUT_SKIP_LOCKED_DIRECTORIES,
} GTCheckoutStrategyType;

// Checkout notification flags used by the various -checkout... methods
// See git_checkout_notify_t
typedef enum {
	GTCheckoutNotifyNone = GIT_CHECKOUT_NOTIFY_NONE,
	GTCheckoutNotifyConflict = GIT_CHECKOUT_NOTIFY_CONFLICT,
	GTCheckoutNotifyDirty = GIT_CHECKOUT_NOTIFY_DIRTY,
	GTCheckoutNotifyUpdated = GIT_CHECKOUT_NOTIFY_UPDATED,
	GTCheckoutNotifyUntracked = GIT_CHECKOUT_NOTIFY_UNTRACKED,
	GTCheckoutNotifyIgnored = GIT_CHECKOUT_NOTIFY_IGNORED,

	GTCheckoutNotifyAll = GIT_CHECKOUT_NOTIFY_ALL,
} GTCheckoutNotifyFlags;

// Transport flags sent as options to +cloneFromURL... method
typedef enum {
	GTTransportFlagsNone = GIT_TRANSPORTFLAGS_NONE,
	// If you pass this flag and the connection is secured with SSL/TLS,
	// the authenticity of the server certificate will not be verified.
	GTTransportFlagsNoCheckCert = GIT_TRANSPORTFLAGS_NO_CHECK_CERT,
} GTTransportFlags;

// An `NSNumber` wrapped `GTTransportFlags`, documented above.
// Default value is `GTTransportFlagsNone`.
extern NSString *const GTRepositoryCloneOptionsTransportFlags;

// An `NSNumber` wrapped `BOOL`, if YES, create a bare clone.
// Default value is `NO`.
extern NSString *const GTRepositoryCloneOptionsBare;

// An `NSNumber` wrapped `BOOL`, if NO, don't checkout the remote HEAD.
// Default value is `YES`.
extern NSString *const GTRepositoryCloneOptionsCheckout;

typedef void (^GTRepositoryStatusBlock)(NSURL *fileURL, GTRepositoryFileStatus status, BOOL *stop);

@interface GTRepository : NSObject

// The file URL for the repository's working directory.
@property (nonatomic, readonly, strong) NSURL *fileURL;
// The file URL for the repository's .git directory.
@property (nonatomic, readonly, strong) NSURL *gitDirectoryURL;
@property (nonatomic, readonly, getter=isBare) BOOL bare; // Is this a 'bare' repository?  i.e. created with git clone --bare
@property (nonatomic, readonly, getter=isEmpty) BOOL empty; // Is this repository empty? Will only be YES for a freshly `git init`'d repo.
@property (nonatomic, readonly, getter=isHEADDetached) BOOL HEADDetached; // Is HEAD detached? i.e., not pointing to a valid reference.
@property (nonatomic, readonly, getter=isHEADOrphaned) BOOL HEADOrphaned; // Is HEAD orphaned? i.e., not pointing to anything.

+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL error:(NSError **)error;
+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL bare:(BOOL)bare error:(NSError **)error;

+ (id)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error;
- (id)initWithURL:(NSURL *)localFileURL error:(NSError **)error;

// Initializes the receiver to wrap the given repository object.
//
// repository - The repository to wrap. The receiver will take over memory
//              management of this object, so it must not be freed elsewhere
//              after this method is invoked. This must not be nil.
//
// Returns an initialized GTRepository.
- (id)initWithGitRepository:(git_repository *)repository;

// The underlying `git_repository` object.
- (git_repository *)git_repository __attribute__((objc_returns_inner_pointer));

// Clone a repository
//
// originURL             - The URL to clone from.
// workdirURL            - A URL to the desired working directory on the local machine.
// options               - A dictionary consisting of the options `GTRepositoryCloneOptionsTransportFlags`, 
//                         `GTRepositoryCloneOptionsBare`, and `GTRepositoryCloneOptionsCheckout`.
// error                 - A pointer to fill in case of trouble.
// transferProgressBlock - This block is called with network transfer updates.
// checkoutProgressBlock - This block is called with checkout updates (if `GTRepositoryCloneOptionsCheckout` is YES).
//
// returns nil (and fills the error parameter) if an error occurred, or a GTRepository object if successful.
+ (id)cloneFromURL:(NSURL *)originURL toWorkingDirectory:(NSURL *)workdirURL options:(NSDictionary *)options error:(NSError **)error transferProgressBlock:(void (^)(const git_transfer_progress *))transferProgressBlock checkoutProgressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))checkoutProgressBlock;

// Helper for getting the sha1 has of a raw object
//
// data - the data to compute a sha1 hash for
// error(out) - will be filled if an error occurs
//
// returns the sha1 for the raw object or nil if there was an error
+ (NSString *)hash:(NSString *)data objectType:(GTObjectType)type error:(NSError **)error;

// Lookup objects in the repo by oid or sha1
- (id)lookupObjectByOID:(GTOID *)oid objectType:(GTObjectType)type error:(NSError **)error;
- (id)lookupObjectByOID:(GTOID *)oid error:(NSError **)error;
- (id)lookupObjectBySHA:(NSString *)sha objectType:(GTObjectType)type error:(NSError **)error;
- (id)lookupObjectBySHA:(NSString *)sha error:(NSError **)error;

// Lookup an object in the repo using a revparse spec
- (id)lookupObjectByRefspec:(NSString *)spec error:(NSError **)error;

// List all references in the repository
//
// repository - The GTRepository to list references in
// error(out) - will be filled if an error occurs
//
// returns an array of NSStrings holding the names of the references
// returns nil if an error occurred and fills the error parameter
- (NSArray *)referenceNamesWithError:(NSError **)error;

// For each file in the repository calls your block with the URL of the file and the status of that file in the repository,
//
// block - the block that gets called for each file
- (void)enumerateFileStatusUsingBlock:(GTRepositoryStatusBlock)block;

// Return YES if the working directory is clean (no modified, new, or deleted files in index)
- (BOOL)isWorkingDirectoryClean;

- (GTReference *)headReferenceWithError:(NSError **)error;

// Convenience methods to return branches in the repository
- (NSArray *)allBranchesWithError:(NSError **)error;

- (NSArray *)localBranchesWithError:(NSError **)error;
- (NSArray *)remoteBranchesWithError:(NSError **)error;
- (NSArray *)branchesWithPrefix:(NSString *)prefix error:(NSError **)error;

// Convenience method to return all tags in the repository
- (NSArray *)allTagsWithError:(NSError **)error;

// Count all commits in the current branch (HEAD)
//
// error(out) - will be filled if an error occurs
//
// returns number of commits in the current branch or NSNotFound if an error occurred
- (NSUInteger)numberOfCommitsInCurrentBranch:(NSError **)error;

// Create a new branch with this name and based off this reference.
//
// name - the name for the new branch
// ref - the reference to create the new branch off
// error(out) - will be filled if an error occurs
//
// returns the new branch or nil if an error occurred.
- (GTBranch *)createBranchNamed:(NSString *)name fromReference:(GTReference *)ref error:(NSError **)error;

// Get the current branch.
//
// error(out) - will be filled if an error occurs
//
// returns the current branch or nil if an error occurred.
- (GTBranch *)currentBranchWithError:(NSError **)error;

// Find the commits that are on our local branch but not on the remote branch.
//
// error(out) - will be filled if an error occurs
//
// returns the local commits, an empty array if there is no remote branch, or nil if an error occurred
- (NSArray *)localCommitsRelativeToRemoteBranch:(GTBranch *)remoteBranch error:(NSError **)error;

// Reset the repository's HEAD to the given commit.
//
// commit - the commit the HEAD is to be reset to. Must not be nil.
// resetType - The type of reset to be used.
// error(out) - in the event of an error this may be set.
//
// Returns `YES` if successful, `NO` if not.
- (BOOL)resetToCommit:(GTCommit *)commit withResetType:(GTRepositoryResetType)resetType error:(NSError **)error;

// Retrieves git's "prepared message" for the next commit, like the default
// message pre-filled when committing after a conflicting merge.
//
// error - If not NULL, set to any error that occurs.
//
// Returns the message from disk, or nil if no prepared message exists or an
// error occurred.
- (NSString *)preparedMessageWithError:(NSError **)error;

// The signature for the user at the current time, based on the repository and
// system configs. If the user's name or email have not been set, reasonable
// defaults will be used instead. Will never return nil.
//
// Returns the signature.
- (GTSignature *)userSignatureForNow;

// Reloads all cached information about the receiver's submodules.
//
// Existing GTSubmodule objects from this repository will be mutated as part of
// this operation.
//
// error - If not NULL, set to any errors that occur.
//
// Returns whether the reload succeeded.
- (BOOL)reloadSubmodules:(NSError **)error;

// Enumerates over all the tracked submodules in the repository.
//
// recursive - Whether to recurse into nested submodules, depth-first.
// block     - A block to execute for each `submodule` found. Setting `stop` to
//             YES will cause enumeration to stop after the block returns. This
//             must not be nil.
- (void)enumerateSubmodulesRecursively:(BOOL)recursive usingBlock:(void (^)(GTSubmodule *submodule, BOOL *stop))block;

// Looks up the top-level submodule with the given name. This will not recurse
// into submodule repositories.
//
// name  - The name of the submodule. This must not be nil.
// error - If not NULL, set to any error that occurs.
//
// Returns the first submodule that matches the given name, or nil if an error
// occurred locating or instantiating the GTSubmodule.
- (GTSubmodule *)submoduleWithName:(NSString *)name error:(NSError **)error;

// Finds the merge base between the commits pointed at by the given OIDs.
//
// firstOID  - The OID for the first commit. This must not be nil.
// secondOID - The OID for the second commit. This must not be nil.
// error     - If not NULL, set to any error that occurs.
//
// Returns the merge base, or nil if none is found or an error occurred.
- (GTCommit *)mergeBaseBetweenFirstOID:(GTOID *)firstOID secondOID:(GTOID *)secondOID error:(NSError **)error;

// The object database backing the repository.
//
// error - The error if one occurred.
//
// Returns the object database, or nil if an error occurred.
- (GTObjectDatabase *)objectDatabaseWithError:(NSError **)error;

// The configuration for the repository.
//
// error - The error if one occurred.
//
// Returns the configuration, or nil if an error occurred.
- (GTConfiguration *)configurationWithError:(NSError **)error;

// The index for the repository.
//
// error - The error if one occurred.
//
// Returns the index, or nil if an error occurred.
- (GTIndex *)indexWithError:(NSError **)error;

// Creates a new lightweight tag in this repository.
//
// name   - Name for the tag; this name is validated
//          for consistency. It should also not conflict with an
//          already existing tag name
// target - Object to which this tag points. This object
//          must belong to this repository.
// error  - Will be filled with a NSError instance on failuer.
//          May be NULL.
//
// Returns YES on success or NO otherwise.
- (BOOL)createLightweightTagNamed:(NSString *)tagName target:(GTObject *)target error:(NSError **)error;

// Creates an annotated tag in this repo. Existing tags are not overwritten.
//
// tagName   - Name for the tag; this name is validated
//             for consistency. It should also not conflict with an
//             already existing tag name
// theTarget - Object to which this tag points. This object
//             must belong to this repository.
// tagger    - Signature of the tagger for this tag, and
//             of the tagging time
// message   - Full message for this tag
// error     - Will be filled with a NSError object in case of error.
//             May be NULL.
//
// Returns the object ID of the newly created tag or nil on error.
- (GTOID *)OIDByCreatingTagNamed:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error;

// Creates an annotated tag in this repo. Existing tags are not overwritten.
//
// tagName   - Name for the tag; this name is validated
//             for consistency. It should also not conflict with an
//             already existing tag name
// theTarget - Object to which this tag points. This object
//             must belong to this repository.
// tagger    - Signature of the tagger for this tag, and
//             of the tagging time
// message   - Full message for this tag
// error     - Will be filled with a NSError object in case of error.
//             May be NULL.
//
// Returns the newly created tag or nil on error.
- (GTTag *)createTagNamed:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error;

// Checkout a commit
//
// targetCommit  - The commit to checkout.
// strategy      - The checkout strategy to use.
// notifyFlags   - Flags that indicate which notifications should cause `notifyBlock`
//                 to be called.
// error         - The error if one occurred. Can be NULL.
// notifyBlock   - The block to call back for notification handling. Can be nil.
// progressBlock - The block to call back for progress updates. Can be nil.
//
// Returns YES if operation was successful, NO otherwise
- (BOOL)checkoutCommit:(GTCommit *)targetCommit strategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags error:(NSError **)error progressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock notifyBlock:(int (^)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir))notifyBlock;

// Checkout a reference
//
// targetCommit  - The reference to checkout.
// strategy      - The checkout strategy to use.
// notifyFlags   - Flags that indicate which notifications should cause `notifyBlock`
//                 to be called.
// error         - The error if one occurred. Can be NULL.
// notifyBlock   - The block to call back for notification handling. Can be nil.
// progressBlock - The block to call back for progress updates. Can be nil.
//
// Returns YES if operation was successful, NO otherwise
- (BOOL)checkoutReference:(GTReference *)targetReference strategy:(GTCheckoutStrategyType)strategy notifyFlags:(GTCheckoutNotifyFlags)notifyFlags error:(NSError **)error progressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock notifyBlock:(int (^)(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir))notifyBlock;

// Convenience wrapper for checkoutCommit:strategy:notifyFlags:error:notifyBlock:progressBlock without notifications
- (BOOL)checkoutCommit:(GTCommit *)target strategy:(GTCheckoutStrategyType)strategy error:(NSError **)error progressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock;

// Convenience wrapper for checkoutReference:strategy:notifyFlags:error:notifyBlock:progressBlock without notifications
- (BOOL)checkoutReference:(GTReference *)target strategy:(GTCheckoutStrategyType)strategy error:(NSError **)error progressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock;

@end
