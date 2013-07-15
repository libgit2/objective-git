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

typedef void (^GTRepositoryStatusBlock)(NSURL *fileURL, GTRepositoryFileStatus status, BOOL *stop);

@interface GTRepository : NSObject

// The file URL for the repository's working directory.
@property (nonatomic, readonly, strong) NSURL *fileURL;
// The file URL for the repository's .git directory.
@property (nonatomic, readonly, strong) NSURL *gitDirectoryURL;
@property (nonatomic, readonly, getter=isBare) BOOL bare; // Is this a 'bare' repository?  i.e. created with git clone --bare
@property (nonatomic, readonly, getter=isEmpty) BOOL empty; // Is this repository empty? Will only be YES for a freshly `git init`'d repo.
@property (nonatomic, readonly, getter=isHeadDetached) BOOL headDetached; // Is HEAD detached? i.e., not pointing to any permanent ref.

+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL error:(NSError **)error;

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
- (GTObject *)lookupObjectByOID:(GTOID *)oid objectType:(GTObjectType)type error:(NSError **)error;
- (GTObject *)lookupObjectByOID:(GTOID *)oid error:(NSError **)error;
- (GTObject *)lookupObjectBySHA:(NSString *)sha objectType:(GTObjectType)type error:(NSError **)error;
- (GTObject *)lookupObjectBySHA:(NSString *)sha error:(NSError **)error;

// Lookup an object in the repo using a revparse spec
- (GTObject *)lookupObjectByRefspec:(NSString *)spec error:(NSError **)error;

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

@end
