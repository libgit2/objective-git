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

@class GTObjectDatabase;
@class GTOdbObject;
@class GTCommit;
@class GTIndex;
@class GTBranch;
@class GTConfiguration;
@class GTDiffFile;

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

typedef enum : git_reset_t {
    GTRepositoryResetTypeSoft = GIT_RESET_SOFT,
    GTRepositoryResetTypeMixed = GIT_RESET_MIXED,
    GTRepositoryResetTypeHard = GIT_RESET_HARD
} GTRepositoryResetType;

typedef enum : git_checkout_strategy_t {
    GTCheckoutStrategyNone = GIT_CHECKOUT_NONE, /** default is a dry run, no actual updates */
    GTCheckoutStrategySafe = GIT_CHECKOUT_SAFE, /** Allow safe updates that cannot overwrite uncommitted data */
    GTCheckoutStrategySafeCreate = GIT_CHECKOUT_SAFE_CREATE, /** Allow safe updates plus creation of missing files */
	GTCheckoutStrategyForce = GIT_CHECKOUT_FORCE, /** Allow all updates to force working directory to look like index */
	GTCheckoutStrategyAllowConflicts = GIT_CHECKOUT_ALLOW_CONFLICTS, /** Allow checkout to make safe updates even if conflicts are found */
	GTCheckoutStrategyRemoveUntracked = GIT_CHECKOUT_REMOVE_UNTRACKED, /** Remove untracked files not in index (that are not ignored) */
	GTCheckoutStrategyRemoveIgnored = GIT_CHECKOUT_REMOVE_IGNORED, /** Remove ignored files not in index */
	GTCheckoutStrategyUpdateOnly = GIT_CHECKOUT_UPDATE_ONLY, /** Only update existing files, don't create new ones */
	GTCheckoutStrategyDontUpdateIndex = GIT_CHECKOUT_DONT_UPDATE_INDEX, /** Normally checkout updates index entries as it goes; this stops that */
	GTCheckoutStrategyNoRefresh = GIT_CHECKOUT_NO_REFRESH, /** Don't refresh index/config/etc before doing checkout */
	GTCheckoutStrategyDisablePathspecMatch = GIT_CHECKOUT_DISABLE_PATHSPEC_MATCH /** Treat pathspec as simple list of exact match file paths */
} GTCheckoutStrategy;

typedef enum : git_checkout_notify_t {
    GTCheckoutNotifyNone = GIT_CHECKOUT_NOTIFY_NONE,
    GTCheckoutNotifyConflict = GIT_CHECKOUT_NOTIFY_CONFLICT,
    GTCheckoutNotifyDirty = GIT_CHECKOUT_NOTIFY_DIRTY,
    GTCheckoutNotifyUpdated = GIT_CHECKOUT_NOTIFY_UPDATED,
    GTCheckoutNotifyUntracked = GIT_CHECKOUT_NOTIFY_UNTRACKED,
    GTCheckoutNotifyIgnored = GIT_CHECKOUT_NOTIFY_IGNORED,
} GTCheckoutNotify;


typedef void (^GTRepositoryStatusBlock)(NSURL *fileURL, GTRepositoryFileStatus status, BOOL *stop);

@interface GTRepository : NSObject <GTObject>

@property (nonatomic, assign, readonly) git_repository *git_repository;
// The file URL for the repository's working directory.
@property (nonatomic, readonly, strong) NSURL *fileURL;
// The file URL for the repository's .git directory.
@property (nonatomic, readonly, strong) NSURL *gitDirectoryURL;
@property (nonatomic, readonly, strong) GTEnumerator *enumerator; // should only be used on the main thread
@property (nonatomic, readonly, strong) GTIndex *index;
@property (nonatomic, readonly, strong) GTObjectDatabase *objectDatabase;
@property (nonatomic, readonly, strong) GTConfiguration *configuration;
@property (nonatomic, readonly, getter=isBare) BOOL bare; // Is this a 'bare' repository?  i.e. created with git clone --bare
@property (nonatomic, readonly, getter=isEmpty) BOOL empty; // Is this repository empty? Will only be YES for a freshly `git init`'d repo.
@property (nonatomic, readonly, getter=isHeadDetached) BOOL headDetached; // Is HEAD detached? i.e., not pointing to any permanent ref.

+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL error:(NSError **)error;

+ (id)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error;
- (id)initWithURL:(NSURL *)localFileURL error:(NSError **)error;

// Clone a repository
//
// originURL             - The URL to clone from.
// workdirURL            - A URL to the desired working directory on the local machine.
// barely                - If YES, create a bare clone
// withCheckout          - if NO, don't checkout the remote HEAD
// error                 - A pointer to fill in case of trouble.
// transferProgressBlock - This block is called with network transfer updates.
// checkoutProgressBlock - This block is called with checkout updates (if withCheckout is YES).
//
// returns nil (and fills the error parameter) if an error occurred, or a GTRepository object if successful.
+ (id)cloneFromURL:(NSURL *)originURL toWorkingDirectory:(NSURL *)workdirURL barely:(BOOL)barely withCheckout:(BOOL)withCheckout error:(NSError **)error transferProgressBlock:(void (^)(const git_transfer_progress *))transferProgressBlock checkoutProgressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))checkoutProgressBlock;

// Helper for getting the sha1 has of a raw object
//
// data - the data to compute a sha1 hash for
// error(out) - will be filled if an error occurs
//
// returns the sha1 for the raw object or nil if there was an error
+ (NSString *)hash:(NSString *)data objectType:(GTObjectType)type error:(NSError **)error;

// Lookup objects in the repo by oid or sha1
- (GTObject *)lookupObjectByOid:(git_oid *)oid objectType:(GTObjectType)type error:(NSError **)error;
- (GTObject *)lookupObjectByOid:(git_oid *)oid error:(NSError **)error;
- (GTObject *)lookupObjectBySha:(NSString *)sha objectType:(GTObjectType)type error:(NSError **)error;
- (GTObject *)lookupObjectBySha:(NSString *)sha error:(NSError **)error;

// Lookup an object in the repo using a revparse spec
- (GTObject *)lookupObjectByRefspec:(NSString *)spec error:(NSError **)error;

// List references in the repository
//
// types - One or more GTReferenceTypes
// error(out) - will be filled if an error occurs
//
// returns an array of NSStrings holding the names of the references
// returns nil if an error occurred and fills the error parameter
- (NSArray *)referenceNamesWithTypes:(GTReferenceTypes)types error:(NSError **)error;

// List all references in the repository
//
// This is a convenience method for listReferencesInRepo: type:GTReferenceTypesListAll error:
//
// repository - The GTRepository to list references in
// error(out) - will be filled if an error occurs
//
// returns an array of NSStrings holding the names of the references
// returns nil if an error occurred and fills the error parameter
- (NSArray *)referenceNamesWithError:(NSError **)error;

- (BOOL)enumerateCommitsBeginningAtSha:(NSString *)sha sortOptions:(GTEnumeratorOptions)options error:(NSError **)error usingBlock:(void (^)(GTCommit *, BOOL *))block;
- (BOOL)enumerateCommitsBeginningAtSha:(NSString *)sha error:(NSError **)error usingBlock:(void (^)(GTCommit *, BOOL *))block;

- (NSArray *)selectCommitsBeginningAtSha:(NSString *)sha error:(NSError **)error block:(BOOL (^)(GTCommit *commit, BOOL *stop))block;

// For each file in the repository calls your block with the URL of the file and the status of that file in the repository,
//
// block - the block that gets called for each file
- (void)enumerateFileStatusUsingBlock:(GTRepositoryStatusBlock)block;

// Return YES if the working directory is clean (no modified, new, or deleted files in index)
- (BOOL)isWorkingDirectoryClean;

- (BOOL)setupIndexWithError:(NSError **)error;

- (GTReference *)headReferenceWithError:(NSError **)error;

// Convenience methods to return branches in the repository
- (NSArray *)allBranchesWithError:(NSError **)error;

- (NSArray *)localBranchesWithError:(NSError **)error;
- (NSArray *)remoteBranchesWithError:(NSError **)error;
- (NSArray *)branchesWithPrefix:(NSString *)prefix error:(NSError **)error;

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

// Pack all references in the repository.
//
// error(out) - will be filled if an error occurs
//
// returns YES if the pack was successful
- (BOOL)packAllWithError:(NSError **)error;

// Reset the repository's HEAD to the given commit.
//
// commit - the commit the HEAD is to be reset to. Must not be nil.
// resetType - The type of reset to be used.
// error(out) - in the event of an error this may be set.
//
// Returns `YES` if successful, `NO` if not.
- (BOOL)resetToCommit:(GTCommit *)commit withResetType:(GTRepositoryResetType)resetType error:(NSError **)error;

- (BOOL)checkout:(NSString *)newTarget
              strategy:(GTCheckoutStrategy)strategy
         progressBlock:(void (^)(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps))progressBlock
           notifyBlock:(int (^)(GTCheckoutNotify why, NSString* path, GTDiffFile* baseline, GTDiffFile* target, GTDiffFile* workdir))notifyBlock
           notifyFlags:(GTCheckoutNotify)notifyFlags
             withError:(NSError **)error;


@end
