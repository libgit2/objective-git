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

#import <Foundation/Foundation.h>
#import "GTBranch.h"
#import "GTEnumerator.h"
#import "GTFilterSource.h"
#import "GTObject.h"
#import "GTReference.h"
#import "GTFilterList.h"
#import "GTCheckoutOptions.h"
#import "git2/checkout.h"
#import "git2/repository.h"
#import "git2/transport.h"
#import "git2/sys/transport.h"

@class GTBlob;
@class GTCommit;
@class GTConfiguration;
@class GTDiffFile;
@class GTIndex;
@class GTObjectDatabase;
@class GTOdbObject;
@class GTSignature;
@class GTSubmodule;
@class GTTag;
@class GTTree;
@class GTRemote;
@class GTNote;

NS_ASSUME_NONNULL_BEGIN

/// Transport flags sent as options to +cloneFromURL... method
typedef NS_OPTIONS(NSInteger, GTTransportFlags) {
	GTTransportFlagsNone = GIT_TRANSPORTFLAGS_NONE
};

/// An `NSNumber` wrapped `GTTransportFlags`, documented above.
/// Default value is `GTTransportFlagsNone`.
extern NSString * const GTRepositoryCloneOptionsTransportFlags;

/// An `NSNumber` wrapped `BOOL`, if YES, create a bare clone.
/// Default value is `NO`.
extern NSString * const GTRepositoryCloneOptionsBare;

/// An `NSNumber` wrapped `BOOL`, if NO, don't checkout the remote HEAD.
/// Default value is `YES`.
extern NSString * const GTRepositoryCloneOptionsPerformCheckout;

/// A `GTCheckoutOptions` object describing how to perform the checkout.
extern NSString * const GTRepositoryCloneOptionsCheckoutOptions;

/// A `GTCredentialProvider`, that will be used to authenticate against the
/// remote.
extern NSString * const GTRepositoryCloneOptionsCredentialProvider;

/// A BOOL indicating whether local clones should actually clone, or just link.
extern NSString * const GTRepositoryCloneOptionsCloneLocal;

/// A NSURL pointing to a local file that contains PEM-encoded certificate chain.
extern NSString * const GTRepositoryCloneOptionsServerCertificateURL;

/// Repository extended open control flags for
/// +initWithURL:flags:ceilingDirs:error:.
///
/// See respository.h for documentation of each individual flag.
typedef NS_OPTIONS(NSInteger, GTRepositoryOpenFlags) {
	GTRepositoryOpenNoSearch = GIT_REPOSITORY_OPEN_NO_SEARCH,
	GTRepositoryOpenCrossFS = GIT_REPOSITORY_OPEN_CROSS_FS,
	GTRepositoryOpenBare = GIT_REPOSITORY_OPEN_BARE,
};

/// Initialization flags associated with `GTRepositoryInitOptionsFlags` for
/// +initializeEmptyRepositoryAtFileURL:options:error:.
///
/// See `git_repository_init_flag_t` for more information.
typedef NS_OPTIONS(NSInteger, GTRepositoryInitFlags) {
	GTRepositoryInitBare = GIT_REPOSITORY_INIT_BARE,
	GTRepositoryInitWithoutReinitializing = GIT_REPOSITORY_INIT_NO_REINIT,
	GTRepositoryInitWithoutDotGit = GIT_REPOSITORY_INIT_NO_DOTGIT_DIR,
	GTRepositoryInitCreatingRepositoryDirectory = GIT_REPOSITORY_INIT_MKDIR,
	GTRepositoryInitCreatingIntermediateDirectories = GIT_REPOSITORY_INIT_MKPATH,
	GTRepositoryInitWithExternalTemplate = GIT_REPOSITORY_INIT_EXTERNAL_TEMPLATE,
	GTRepositoryInitWithRelativeGitLink = GIT_REPOSITORY_INIT_RELATIVE_GITLINK,
};

/// An `NSNumber` wrapping `GTRepositoryInitFlags` with which to initialize the
/// repository.
extern NSString * const GTRepositoryInitOptionsFlags;

/// An `NSNumber` wrapping a `mode_t` or `git_repository_init_mode_t` to use
/// for the initialized repository.
extern NSString * const GTRepositoryInitOptionsMode;

/// An `NSString` to the working directory that should be used. If this is a
/// relative path, it will be resolved against the repository path.
extern NSString * const GTRepositoryInitOptionsWorkingDirectoryPath;

/// An `NSString` of the Git description to use for the new repository.
extern NSString * const GTRepositoryInitOptionsDescription;

/// A file `NSURL` to the template directory that should be used instead of the
/// defaults, if the `GTRepositoryInitWithExternalTemplate` flag is specified.
extern NSString * const GTRepositoryInitOptionsTemplateURL;

/// An `NSString` of the name to use for the initial `HEAD` reference.
extern NSString * const GTRepositoryInitOptionsInitialHEAD;

/// An `NSString` representing an origin URL to add to the repository after
/// initialization.
extern NSString * const GTRepositoryInitOptionsOriginURLString;

/// The possible states for the repository to be in, based on the current ongoing operation.
typedef NS_ENUM(NSInteger, GTRepositoryStateType) {
	GTRepositoryStateNone = GIT_REPOSITORY_STATE_NONE,
	GTRepositoryStateMerge = GIT_REPOSITORY_STATE_MERGE,
	GTRepositoryStateRevert = GIT_REPOSITORY_STATE_REVERT,
	GTRepositoryStateCherryPick = GIT_REPOSITORY_STATE_CHERRYPICK,
	GTRepositoryStateBisect = GIT_REPOSITORY_STATE_BISECT,
	GTRepositoryStateRebase = GIT_REPOSITORY_STATE_REBASE,
	GTRepositoryStateRebaseInteractive = GIT_REPOSITORY_STATE_REBASE_INTERACTIVE,
	GTRepositoryStateRebaseMerge = GIT_REPOSITORY_STATE_REBASE_MERGE,
	GTRepositoryStateApplyMailbox = GIT_REPOSITORY_STATE_APPLY_MAILBOX,
	GTRepositoryStateApplyMailboxOrRebase = GIT_REPOSITORY_STATE_APPLY_MAILBOX_OR_REBASE,
};

@interface GTRepository : NSObject

/// The file URL for the repository's working directory.
/// Returns nil for a bare repository.
@property (nonatomic, readonly, strong) NSURL * _Nullable fileURL;
/// The file URL for the repository's .git directory.
@property (nonatomic, readonly, strong) NSURL * _Nullable gitDirectoryURL;

/// Is this a bare repository (one without a working directory)?
@property (nonatomic, readonly, getter = isBare) BOOL bare;

/// Is this an empty (freshly initialized) repository?
@property (nonatomic, readonly, getter = isEmpty) BOOL empty;

/// Is HEAD detached (not pointing to a branch or tag)?
@property (nonatomic, readonly, getter = isHEADDetached) BOOL HEADDetached;

/// Is HEAD unborn (pointing to a branch without an initial commit)?
@property (nonatomic, readonly, getter = isHEADUnborn) BOOL HEADUnborn;

/// Initializes a new repository at the given file URL.
///
/// fileURL - The file URL for the new repository. Cannot be nil.
/// options - A dictionary of `GTRepositoryInitOptions…` keys controlling how
///           the repository is initialized, or nil to use the defaults.
/// error   - The error if one occurs.
///
/// Returns the initialized repository, or nil if an error occurred.
+ (instancetype _Nullable)initializeEmptyRepositoryAtFileURL:(NSURL *)fileURL options:(NSDictionary * _Nullable)options error:(NSError **)error;

/// Convenience class initializer which uses the default options.
///
/// localFileURL - The file URL for the new repository. Cannot be nil.
/// error        - The error if one occurs.
///
/// Returns the initialized repository, or nil if an error occurred.
+ (instancetype _Nullable)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error;

/// Convenience initializer which uses the default options.
///
/// localFileURL - The file URL for the new repository. Cannot be nil.
/// error        - The error if one occurs.
///
/// Returns the initialized repository, or nil if an error occurred.
- (instancetype _Nullable)initWithURL:(NSURL *)localFileURL error:(NSError **)error;

/// Convenience initializer to find and open a repository with extended controls.
///
/// localFileURL    - The file URL for the new repository. Cannot be nil.
/// flags           - A combination of the `GTRepositoryOpenFlags` flags.
/// ceilingDirURLs  - An array of URLs at which the search for a containing
///                   repository should terminate. Can be NULL.
/// error           - The error if one occurs.
///
/// Returns the initialized repository, or nil if an error occurred.
- (instancetype _Nullable)initWithURL:(NSURL *)localFileURL flags:(NSInteger)flags ceilingDirs:(NSArray<NSURL *> * _Nullable)ceilingDirURLs error:(NSError **)error;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver to wrap the given repository object. Designated initializer.
///
/// repository - The repository to wrap. The receiver will take over memory
///              management of this object, so it must not be freed elsewhere
///              after this method is invoked. This must not be nil.
///
/// Returns an initialized GTRepository, or nil if an erroe occurred.
- (instancetype _Nullable)initWithGitRepository:(git_repository *)repository NS_DESIGNATED_INITIALIZER;

/// The underlying `git_repository` object.
- (git_repository *)git_repository __attribute__((objc_returns_inner_pointer));

/// Clone a repository
///
/// originURL             - The URL to clone from. Must not be nil.
/// workdirURL            - A URL to the desired working directory on the local machine. Must not be nil.
/// options               - A dictionary consisting of the options:
///                         `GTRepositoryCloneOptionsTransportFlags`,
///                         `GTRepositoryCloneOptionsBare`,
///                         `GTRepositoryCloneOptionsPerformCheckout`,
///                         `GTRepositoryCloneOptionsCheckoutOptions`,
///                         `GTRepositoryCloneOptionsCredentialProvider`,
///                         `GTRepositoryCloneOptionsCloneLocal`,
///                         `GTRepositoryCloneOptionsServerCertificateURL`
/// error                 - A pointer to fill in case of trouble.
/// transferProgressBlock - This block is called with network transfer updates.
///                         May be NULL.
///                         May be NULL.
///
/// returns nil (and fills the error parameter) if an error occurred, or a GTRepository object if successful.
+ (instancetype _Nullable)cloneFromURL:(NSURL *)originURL toWorkingDirectory:(NSURL *)workdirURL options:(NSDictionary * _Nullable)options error:(NSError **)error transferProgressBlock:(void (^ _Nullable)(const git_transfer_progress *, BOOL *stop))transferProgressBlock;

/// Lookup objects in the repo by oid or sha1
- (id _Nullable)lookUpObjectByOID:(GTOID *)oid objectType:(GTObjectType)type error:(NSError **)error;
- (id _Nullable)lookUpObjectByOID:(GTOID *)oid error:(NSError **)error;
- (id _Nullable)lookUpObjectBySHA:(NSString *)sha objectType:(GTObjectType)type error:(NSError **)error;
- (id _Nullable)lookUpObjectBySHA:(NSString *)sha error:(NSError **)error;

/// Lookup an object in the repo using a revparse spec
- (id _Nullable)lookUpObjectByRevParse:(NSString *)spec error:(NSError **)error;

/// Finds the branch with the given name and type.
///
/// branchName - The name of the branch to look up (e.g., `master` or
///              `origin/master`). This must not be nil.
/// branchType - Whether the branch to look up is local or remote.
/// success    - If not NULL, set to whether the branch lookup finished without
///              any errors. This can be `YES` even if no matching branch is
///              found.
/// error      - If not NULL, set to any error that occurs.
///
/// Returns the matching branch, or nil if no match was found or an error occurs.
/// The latter two cases can be distinguished by checking `success`.
- (GTBranch * _Nullable)lookUpBranchWithName:(NSString *)branchName type:(GTBranchType)branchType success:(BOOL * _Nullable)success error:(NSError **)error;

/// List all references in the repository
///
/// repository - The GTRepository to list references in
/// error(out) - will be filled if an error occurs
///
/// returns an array of NSStrings holding the names of the references
/// returns nil if an error occurred and fills the error parameter
- (NSArray<NSString *> * _Nullable)referenceNamesWithError:(NSError **)error;

/// Get the HEAD reference.
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns a GTReference or nil if an error occurs.
- (GTReference * _Nullable)headReferenceWithError:(NSError **)error;

/// Move HEAD reference safely, since deleting and recreating HEAD is always wrong.
///
/// reference - The new target reference for HEAD.
/// error     - If not NULL, set to any error that occurs.
///
/// Returns NO if an error occurs.
- (BOOL)moveHEADToReference:(GTReference *)reference error:(NSError **)error;

/// Move HEAD reference safely, since deleting and recreating HEAD is always wrong.
///
/// commit - The commit which HEAD should point to.
/// error  - If not NULL, set to any error that occurs.
///
/// Returns NO if an error occurs.
- (BOOL)moveHEADToCommit:(GTCommit *)commit error:(NSError **)error;

/// Get the local branches.
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns an array of GTBranches or nil if an error occurs.
- (NSArray<GTBranch *> * _Nullable)localBranchesWithError:(NSError **)error;

/// Get the remote branches.
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns an array of GTBranches or nil if an error occurs.
- (NSArray<GTBranch *> * _Nullable)remoteBranchesWithError:(NSError **)error;

/// Get branches with names sharing a given prefix.
///
/// prefix - The prefix to use for filtering. Must not be nil.
/// error  - If not NULL, set to any error that occurs.
///
/// Returns an array of GTBranches or nil if an error occurs.
- (NSArray<GTBranch *> * _Nullable)branchesWithPrefix:(NSString *)prefix error:(NSError **)error;

/// Get the local and remote branches and merge them together by combining local
/// branches with their remote branch, if they have one.
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns an array of GTBranches or nil if an error occurs.
- (NSArray<GTBranch *> * _Nullable)branches:(NSError **)error;

/// List all remotes in the repository
///
/// error - will be filled if an error occurs
///
/// returns an array of NSStrings holding the names of the remotes, or nil if an error occurred
- (NSArray<NSString *> * _Nullable)remoteNamesWithError:(NSError **)error;

/// Get all tags in the repository.
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns an array of GTTag or nil if an error occurs.
- (NSArray<GTTag *> * _Nullable)allTagsWithError:(NSError **)error;

/// Count all commits in the current branch (HEAD)
///
/// error(out) - will be filled if an error occurs
///
/// returns number of commits in the current branch or NSNotFound if an error occurred
- (NSUInteger)numberOfCommitsInCurrentBranch:(NSError **)error;

/// Creates a direct reference to the given OID.
///
/// name      - The full name for the new reference. This must not be nil.
/// targetOID - The OID that the new ref should point to. This must not be nil.
/// message   - A message to use when creating the reflog entry for this action.
///             This may be nil.
/// error     - If not NULL, set to any error that occurs.
///
/// Returns the created ref, or nil if an error occurred.
- (GTReference * _Nullable)createReferenceNamed:(NSString *)name fromOID:(GTOID *)targetOID message:(NSString * _Nullable)message error:(NSError **)error;

/// Creates a symbolic reference to another ref.
///
/// name      - The full name for the new reference. This must not be nil.
/// targetRef - The ref that the new ref should point to. This must not be nil.
/// message   - A message to use when creating the reflog entry for this action.
///             This may be nil.
/// error     - If not NULL, set to any error that occurs.
///
/// Returns the created ref, or nil if an error occurred.
- (GTReference * _Nullable)createReferenceNamed:(NSString *)name fromReference:(GTReference *)targetRef message:(NSString * _Nullable)message error:(NSError **)error;

/// Create a new local branch pointing to the given OID.
///
/// name      - The name for the new branch (e.g., `master`). This must not be
///             nil.
/// targetOID - The OID to create the new branch off. This must not be nil.
/// message   - A message to use when creating the reflog entry for this action.
///             This may be nil.
/// error     - If not NULL, set to any error that occurs.
///
/// Returns the new branch, or nil if an error occurred.
- (GTBranch * _Nullable)createBranchNamed:(NSString *)name fromOID:(GTOID *)targetOID message:(NSString * _Nullable)message error:(NSError **)error;

/// Get the current branch.
///
/// error(out) - will be filled if an error occurs
///
/// returns the current branch or nil if an error occurred.
- (GTBranch * _Nullable)currentBranchWithError:(NSError **)error;

/// Find the commits that are on our local branch but not on the remote branch.
///
/// remoteBranch - The remote branch to use as a reference. Must not be nil.
/// error(out)   - will be filled if an error occurs
///
/// returns the local commits, an empty array if there is no remote branch, or nil if an error occurred
- (NSArray<GTCommit *> * _Nullable)localCommitsRelativeToRemoteBranch:(GTBranch *)remoteBranch error:(NSError **)error;

/// Retrieves git's "prepared message" for the next commit, like the default
/// message pre-filled when committing after a conflicting merge.
///
/// error - If not NULL, set to any error that occurs.
///
/// Returns the message from disk, or nil if no prepared message exists or an
/// error occurred.
- (NSString * _Nullable)preparedMessageWithError:(NSError **)error;

/// The signature for the user at the current time, based on the repository and
/// system configs. If the user's name or email have not been set, reasonable
/// defaults will be used instead. Will never return nil.
///
/// Returns the signature.
- (GTSignature *)userSignatureForNow;

/// Enumerates over all the tracked submodules in the repository.
///
/// recursive - Whether to recurse into nested submodules, depth-first.
/// block     - A block to execute for each `submodule` found. If an error
///             occurred while reading the submodule, `submodule` will be nil and
///             `error` will contain the error information. Setting `stop` to YES
///             will cause enumeration to stop after the block returns. This must
///             not be nil.
- (void)enumerateSubmodulesRecursively:(BOOL)recursive usingBlock:(void (^)(GTSubmodule * _Nullable submodule, NSError *error, BOOL *stop))block;

/// Looks up the top-level submodule with the given name. This will not recurse
/// into submodule repositories.
///
/// name  - The name of the submodule. This must not be nil.
/// error - If not NULL, set to any error that occurs.
///
/// Returns the first submodule that matches the given name, or nil if an error
/// occurred locating or instantiating the GTSubmodule.
- (GTSubmodule * _Nullable)submoduleWithName:(NSString *)name error:(NSError **)error;

/// Finds the merge base between the commits pointed at by the given OIDs.
///
/// firstOID  - The OID for the first commit. This must not be nil.
/// secondOID - The OID for the second commit. This must not be nil.
/// error     - If not NULL, set to any error that occurs.
///
/// Returns the merge base, or nil if none is found or an error occurred.
- (GTCommit * _Nullable)mergeBaseBetweenFirstOID:(GTOID *)firstOID secondOID:(GTOID *)secondOID error:(NSError **)error;

/// The object database backing the repository.
///
/// error - The error if one occurred.
///
/// Returns the object database, or nil if an error occurred.
- (GTObjectDatabase * _Nullable)objectDatabaseWithError:(NSError **)error;

/// The configuration for the repository.
///
/// error - The error if one occurred.
///
/// Returns the configuration, or nil if an error occurred.
- (GTConfiguration * _Nullable)configurationWithError:(NSError **)error;

/// The index for the repository.
///
/// error - The error if one occurred.
///
/// Returns the index, or nil if an error occurred.
- (GTIndex * _Nullable)indexWithError:(NSError **)error;

/// Creates a new lightweight tag in this repository.
///
/// name   - Name for the tag; this name is validated
///          for consistency. It should also not conflict with an
///          already existing tag name. Must not be nil.
/// target - Object to which this tag points. This object
///          must belong to this repository. Must not be nil.
/// error  - Will be filled with a NSError instance on failuer.
///          May be NULL.
///
/// Returns YES on success or NO otherwise.
- (BOOL)createLightweightTagNamed:(NSString *)tagName target:(GTObject *)target error:(NSError **)error;

/// Creates an annotated tag in this repo. Existing tags are not overwritten.
///
/// tagName   - Name for the tag; this name is validated
///             for consistency. It should also not conflict with an
///             already existing tag name
/// theTarget - Object to which this tag points. This object
///             must belong to this repository.
/// tagger    - Signature of the tagger for this tag, and
///             of the tagging time
/// message   - Full message for this tag
/// error     - Will be filled with a NSError object in case of error.
///             May be NULL.
///
/// Returns the object ID of the newly created tag or nil on error.
- (GTOID * _Nullable)OIDByCreatingTagNamed:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error;

/// Creates an annotated tag in this repo. Existing tags are not overwritten.
///
/// tagName   - Name for the tag; this name is validated
///             for consistency. It should also not conflict with an
///             already existing tag name
/// theTarget - Object to which this tag points. This object
///             must belong to this repository.
/// tagger    - Signature of the tagger for this tag, and
///             of the tagging time
/// message   - Full message for this tag
/// error     - Will be filled with a NSError object in case of error.
///             May be NULL.
///
/// Returns the newly created tag or nil on error.
- (GTTag * _Nullable)createTagNamed:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error;

/// Checkout a commit
///
/// targetCommit  - The commit to checkout. Must not be nil.
/// options       - The checkout options to use. Can be nil.
/// error         - The error if one occurred. Can be NULL.
///
/// Returns YES if operation was successful, NO otherwise
- (BOOL)checkoutCommit:(GTCommit *)targetCommit options:(GTCheckoutOptions * _Nullable)options error:(NSError **)error;

/// Checkout a reference
///
/// targetReference  - The reference to checkout. Must not be nil.
/// options          - The checkout options to use. Can be nil.
/// error            - The error if one occurred. Can be NULL.
///
/// Returns YES if operation was successful, NO otherwise
- (BOOL)checkoutReference:(GTReference *)targetReference options:(GTCheckoutOptions * _Nullable)options error:(NSError **)error;

/// Checkout an index
///
/// index   - The index to checkout. Must not be nil.
/// options - The checkout options to use. Can be nil.
/// error   - The error if one occurred. Can be NULL.
///
/// Returns YES if operation was successful, NO otherwise
- (BOOL)checkoutIndex:(GTIndex *)index options:(GTCheckoutOptions * _Nullable)options error:(NSError **)error;

/// Checkout a tree
///
/// targetTree    - The tree to checkout.
/// options       - The checkout options to use. Can be nil.
/// error         - The error if one occurred. Can be NULL.
///
/// Returns YES if operation was successful, NO otherwise
/// Note: this operation will NOT update HEAD to newly checked out tree.
- (BOOL)checkoutTree:(GTTree *)targetTree options:(GTCheckoutOptions * _Nullable)options error:(NSError **)error;

/// Flush the gitattributes cache.
- (void)flushAttributesCache;

/// Loads the filter list for a given path in the repository.
///
/// path    - The path to load filters for. This is used to determine which
///           filters to apply, and does not necessarily need to point to a file
///           that already exists. This must not be nil.
/// blob    - The blob to which the filter will be applied, if known. This is
///           used to determine which filters to apply, and can differ from the
///           content of the file at `path`. This may be nil.
/// mode    - The direction in which the data will be filtered.
/// options - The list options. See the libgit2 header for more information.
/// success - If not NULL, set to `NO` if an error occurs. If `nil` is
///           returned and this argument is set to `YES`, there were no filters
///           to apply.
/// error   - If not NULL, set to any error that occurs.
///
/// Returns the loaded filter list, or nil if an error occurs or there are no
/// filters to apply to the given path. The latter two cases can be
/// distinguished using the value of `success`.
- (GTFilterList * _Nullable)filterListWithPath:(NSString *)path blob:(GTBlob * _Nullable)blob mode:(GTFilterSourceMode)mode options:(GTFilterListOptions)options success:(BOOL * _Nullable)success error:(NSError **)error;

/// Calculates how far ahead/behind the commit represented by `headOID` is,
/// relative to the commit represented by `baseOID`.
///
/// ahead   - Must not be NULL.
/// behind  - Must not be NULL.
/// headOID - Must not be nil.
/// baseOID - Must not be nil.
/// error   - If not NULL, set to any error that occurs.
///
/// Returns whether `ahead` and `behind` were successfully calculated.
- (BOOL)calculateAhead:(size_t *)ahead behind:(size_t *)behind ofOID:(GTOID *)headOID relativeToOID:(GTOID *)baseOID error:(NSError **)error;

/// Creates an enumerator for walking the unique commits, as determined by a
/// pushing a starting OID and hiding the relative OID.
///
/// fromOID     - The starting OID.
/// relativeOID - The OID to hide.
/// error       - The error if one occurred.
///
/// Returns the enumerator or nil if an error occurred.
- (GTEnumerator * _Nullable)enumeratorForUniqueCommitsFromOID:(GTOID *)fromOID relativeToOID:(GTOID *)relativeOID error:(NSError **)error;

/// Determines the status of a git repository--i.e., whether an operation
/// (merge, cherry-pick, etc) is in progress.
///
/// state - A pointer to set the retrieved state. Must not be NULL.
/// error - The error if one occurred.
///
/// Returns YES if operation was successful, NO otherwise
- (BOOL)calculateState:(GTRepositoryStateType *)state withError:(NSError **)error;

/// Remove all the metadata associated with an ongoing command like merge,
/// revert, cherry-pick, etc.  For example: MERGE_HEAD, MERGE_MSG, etc.
///
/// error - The error if one occurred.
///
/// Returns YES if operation was successful, NO otherwise
- (BOOL)cleanupStateWithError:(NSError * _Nullable __autoreleasing *)error;

/// Creates a new note in this repo (using a default notes reference, e.g. "refs/notes/commits")
///
/// note          - Note text.
/// theTarget     - Object (usually a commit) to which this note refers to.
///                 This object must belong to this repository.
/// referenceName - Name for the notes reference in the repo, or nil for default ("refs/notes/commits")
/// author        - Signature of the author for this note, and
///                 of the note creation time
/// committer     - Signature of the committer for this note.
/// overwrite     - If set to YES, the note will be overwritten if it already exists.
/// error         - Will be filled with a NSError object in case of error.
///                 May be NULL.
///
/// Returns the newly created note or nil on error.
- (GTNote * _Nullable)createNote:(NSString *)note target:(GTObject *)theTarget referenceName:(NSString * _Nullable)referenceName author:(GTSignature *)author committer:(GTSignature *)committer overwriteIfExists:(BOOL)overwrite error:(NSError **)error;

/// Removes a note attached to object in this repo
///
/// parentObject  - Object (usually a commit) to which the note to be removed is attached to.
///                 This object must belong to this repository.
/// referenceName - Name for the notes reference in the repo, or nil for default ("refs/notes/commits")
/// author        - Signature of the author for this note removal, and
///                 of the note removal time
/// committer     - Signature of the committer for this note removal.
/// error         - Will be filled with a NSError object in case of error.
///                 May be NULL.
///
/// Returns the YES on success and NO on error.
- (BOOL)removeNoteFromObject:(GTObject *)parentObject referenceName:(NSString * _Nullable)referenceName author:(GTSignature *)author committer:(GTSignature *)committer error:(NSError **)error;

/// Enumerates through all stored notes in this repo
///
/// referenceName - Name for the notes reference in the repo, or nil for default ("refs/notes/commits")
/// error         - Will be filled with a NSError object in case of error.
///                 May be NULL.
/// block         - A block to be called on each encountered note object. The block accepts
///                 a reference to `note`, an `object` that is annotated with the note.
///                 If the block sets `stop` to YES, the iterator is finished.
///
/// Returns YES on overall success or NO on error of any kind.
- (BOOL)enumerateNotesWithReferenceName:(NSString * _Nullable)referenceName error:(NSError **)error usingBlock:(void (^)(GTNote * _Nullable note, GTObject * _Nullable object, NSError * _Nullable error, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
