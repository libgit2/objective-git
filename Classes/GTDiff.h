//
//  GTDiff.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 29/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

#import "GTDiffDelta.h"

@class GTDiffDelta;
@class GTRepository;
@class GTTree;

// An `NSNumber` wrapped `GTDiffOptionsFlags` representing any flags you wish to
// pass into the initialisation.
extern NSString *const GTDiffOptionsFlagsKey;

// An `NSNumber` wrapped `NSUInteger` dictating the number of unchanged lines
// that define the boundary of a hunk (and to display around it).
//
// Defaults to 3.
extern NSString *const GTDiffOptionsContextLinesKey;

// An `NSNumber` wrapped `NSUInteger` dictating the maximum number of unchanged
// lines between hunk boundaries before the hunks will be merged.
//
// Defaults to 0.
extern NSString *const GTDiffOptionsInterHunkLinesKey;

// An `NSString` to prefix old file names with.
//
// Defaults to "a".
extern NSString *const GTDiffOptionsOldPrefixKey;

// An `NSString` to prefix new file names with.
//
// Defaults to "b".
extern NSString *const GTDiffOptionsNewPrefixKey;

// An `NSNumber` wrapped `NSUInteger` determining the maximum size (in bytes)
// of a file to diff. Above this size the file will be treated as binary.
//
// Defaults to 512MB.
extern NSString *const GTDiffOptionsMaxSizeKey;

// An `NSArray` of `NSStrings`s to limit the diff to specific paths inside the
// repository.  The entries in the array represent either single paths or
// filename patterns with wildcard matching a la standard shell glob (see
// http://linux.die.net/man/7/glob for wildcard matching rules).
//
// The diff will only contain the files or patterns included in this options
// array.
//
// Defaults to including all files.
extern NSString *const GTDiffOptionsPathSpecArrayKey;

// Enum for use as documented in the options dictionary with the
// `GTDiffOptionsFlagsKey` key.
//
// See diff.h for documentation of each individual flag. 
typedef enum {
	GTDiffOptionsFlagsNormal = GIT_DIFF_NORMAL,

	/*
	 * Options controlling which files will be in the diff
	 */

	GTDiffOptionsFlagsReverse = GIT_DIFF_REVERSE,
	GTDiffOptionsFlagsIncludeIgnored = GIT_DIFF_INCLUDE_IGNORED,
	GTDiffOptionsFlagsRecurseIgnoredDirs = GIT_DIFF_RECURSE_IGNORED_DIRS,
	GTDiffOptionsFlagsIncludeUntracked = GIT_DIFF_INCLUDE_UNTRACKED,
	GTDiffOptionsFlagsRecurseUntrackedDirs = GIT_DIFF_RECURSE_UNTRACKED_DIRS,
	GTDiffOptionsFlagsIncludeUnmodified = GIT_DIFF_INCLUDE_UNMODIFIED,
	GTDiffOptionsFlagsIncludeTypeChange = GIT_DIFF_INCLUDE_TYPECHANGE,
	GTDiffOptionsFlagsIncludeTypeChangeTrees = GIT_DIFF_INCLUDE_TYPECHANGE_TREES,
	GTDiffOptionsFlagsIgnoreFileMode = GIT_DIFF_IGNORE_FILEMODE,
	GTDiffOptionsFlagsIgnoreSubmodules = GIT_DIFF_IGNORE_SUBMODULES,
	GTDiffOptionsFlagsIgnoreCase = GIT_DIFF_IGNORE_CASE,
	GTDiffOptionsFlagsDisablePathspecMatch = GIT_DIFF_DISABLE_PATHSPEC_MATCH,
	GTDiffOptionsFlagsSkipBinaryCheck = GIT_DIFF_SKIP_BINARY_CHECK,
	GTDiffOptionsFlagsEnableFastUntrackedDirs = GIT_DIFF_ENABLE_FAST_UNTRACKED_DIRS,

	/*
	 * Options controlling how output will be generated
	 */

	GTDiffOptionsFlagsForceText = GIT_DIFF_FORCE_TEXT,
	GTDiffOptionsFlagsForceBinary = GIT_DIFF_FORCE_BINARY,
	GTDiffOptionsFlagsIgnoreWhitespace = GIT_DIFF_IGNORE_WHITESPACE,
	GTDiffOptionsFlagsIgnoreWhitespaceChange = GIT_DIFF_IGNORE_WHITESPACE_CHANGE,
	GTDiffOptionsFlagsIgnoreWhitespaceEOL = GIT_DIFF_IGNORE_WHITESPACE_EOL,
	GTDiffOptionsFlagsShowUntrackedContent = GIT_DIFF_SHOW_UNTRACKED_CONTENT,
	GTDiffOptionsFlagsShowUnmodified = GIT_DIFF_SHOW_UNMODIFIED,

	GTDiffOptionsFlagsPatience = GIT_DIFF_PATIENCE,
	GTDiffOptionsFlagsMinimal = GIT_DIFF_MINIMAL,
} GTDiffOptionsFlags;

// An `NSNumber` wrapped `GTDiffOptionsFlags` bitmask containing any of the
// flags documented below.
//
// Defualts to `GTDiffFindOptionsFlagsFindRenames`.
extern NSString *const GTDiffFindOptionsFlagsKey;

// An `NSNumber` wrapped `NSUInteger` dictating the similarity between files
// to be considered a rename.
//
// This is a value as per the git similarity index and should be between 1 and
// 100 (0 and above 100 use the default).
//
// Defaults to 50.
extern NSString *const GTDiffFindOptionsRenameThresholdKey;

// An `NSNumber` wrapped `NSUInteger` dictating how similar a modified file can
// be to be eligable as a rename.
//
// This is a value as per the git similarity index and should be between 1 and
// 100 (0 and above 100 use the default).
//
// Defaults to 50.
extern NSString *const GTDiffFindOptionsRenameFromRewriteThresholdKey;

// An `NSNumber` wrapped `NSUInteger` dictating how similar a modified file can
// be to be considered a copy.
//
// This is a value as per the git similarity index and should be between 1 and
// 100 (0 and above 100 use the default).
//
// Defaults to 50.
extern NSString *const GTDiffFindOptionsCopyThresholdKey;

// An `NSNumber` wrapped `NSUInteger` dictating how similar a modified file can
// be to be to be broken into a separate deletion and addition pair.
//
// This is a value as per the git similarity index and should be between 1 and
// 100 (0 and above 100 use the default).
//
// Defaults to 60.
extern NSString *const GTDiffFindOptionsBreakRewriteThresholdKey;

// An `NSNumber` wrapped `NSUInteger` dictating the maximum amount of similarity
// sources to examine.
//
// This is the equivalent of the `diff.renameLimit` config value.
//
// Defaults to 200.
extern NSString *const GTDiffFindOptionsRenameLimitKey;

// Enum for options passed into `-findSimilarWithOptions:`.
//
// For individual case documentation see `diff.h`.
typedef enum {
	GTDiffFindOptionsFlagsFindRenames = GIT_DIFF_FIND_RENAMES,
	GTDiffFindOptionsFlagsFindRenamesFromRewrites = GIT_DIFF_FIND_RENAMES_FROM_REWRITES,
	GTDiffFindOptionsFlagsFindCopies = GIT_DIFF_FIND_COPIES,
	GTDiffFindOptionsFlagsFindCopiesFromUnmodified = GIT_DIFF_FIND_COPIES_FROM_UNMODIFIED,
	GTDiffFindOptionsFlagsFindRewrites = GIT_DIFF_FIND_REWRITES,
	GTDiffFindOptionsFlagsBreakRewrites = GIT_DIFF_BREAK_REWRITES,
	GTDiffFindOptionsFlagsFindAndBreakRewrites = GIT_DIFF_FIND_AND_BREAK_REWRITES,

	GTDiffFindOptionsFlagsFindForUntracked = GIT_DIFF_FIND_FOR_UNTRACKED,
	GTDiffFindAll = GIT_DIFF_FIND_ALL,

	GTDiffFindOptionsFlagsIgnoreLeadingWhitespace = GIT_DIFF_FIND_IGNORE_LEADING_WHITESPACE,
	GTDiffFindOptionsFlagsIgnoreWhitespace = GIT_DIFF_FIND_IGNORE_WHITESPACE,
	GTDiffFindOptionsFlagsDontIgnoreWhitespace = GIT_DIFF_FIND_DONT_IGNORE_WHITESPACE,
	GTDiffFindOptionsFlagsExactMatchOnly = GIT_DIFF_FIND_EXACT_MATCH_ONLY,

	GTDiffFindOptionsFlagsBreakRewritesForRenamesOnly = GIT_DIFF_BREAK_REWRITES_FOR_RENAMES_ONLY,
} GTDiffFindOptionsFlags;

// A class representing a single "diff".
//
// Analagous to `git_diff_list` in libgit2, this object represents a list of
// changes or "deltas", which are represented by `GTDiffDelta` objects.
@interface GTDiff : NSObject

// The number of deltas represented by the diff object.
@property (nonatomic, readonly) NSUInteger deltaCount;

// Create a diff between 2 `GTTree`s.
//
// The 2 trees must be from the same repository, or an exception will be thrown.
//
// oldTree    - The "left" side of the diff. May be nil to represent an empty
//              tree.
// newTree    - The "right" side of the diff. May be nil to represent an empty
//              tree.
// repository - The repository to be used for the diff. Cannot be nil.
// options    - A dictionary containing any of the above options key constants, or
//              nil to use the defaults.
// error      - Populated with an `NSError` object on error, if information is
//              available.
//
// Returns a newly created `GTDiff` object or nil on error.
+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error;

// Create a diff between a repository's current index.
//
// This is equivalent to `git diff --cached <treeish>` or if you pass the HEAD
// tree, then `git diff --cached`.
//
// The tree you pass will be used for the "left" side of the diff, and the
// index will be used for the "right" side of the diff.
//
// tree       - The tree to be diffed. The index will be taken from this tree's
//              repository. The left side of the diff. May be nil to represent an
//              empty tree.
// repository - The repository to be used for the diff.
// options    - A dictionary containing any of the above options key constants, or
//              nil to use the defaults.
// error      - Populated with an `NSError` object on error, if information is
//              available.
//
// Returns a newly created `GTDiff` object or nil on error.
+ (GTDiff *)diffIndexFromTree:(GTTree *)tree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error;

// Create a diff between the index and working directory in a given repository.
//
// This matches the `git diff` command.
//
// repository - The repository to be used for the diff.
// options    - A dictionary containing any of the above options key constants,
//              or nil to use the defaults.
// error      - Populated with an `NSError` object on error, if information is
//              available.
//
// Returns a newly created `GTDiff` object or nil on error.
+ (GTDiff *)diffIndexToWorkingDirectoryInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error;

// Create a diff between a repository's working directory and a tree.
//
// tree       - The tree to be diffed. The tree will be the left side of the diff.
//              May be nil to represent an empty tree.
// repository - The repository to be used for the diff.
// options    - A dictionary containing any of the above options key constants, or
//              nil to use the defaults.
// error      - Populated with an `NSError` object on error, if information is
//              available.
//
// Returns a newly created `GTDiff` object or nil on error.
+ (GTDiff *)diffWorkingDirectoryFromTree:(GTTree *)tree inRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error;

// Create a diff between the working directory and HEAD.
//
// If the repository does not have a HEAD commit yet, this will create a diff of
// the working directory as if everything would be part of the initial commit.
//
// repository - The repository to be used for the diff.
// options    - A dictionary containing any of the above options key constants,
//              or nil to use the defaults.
// error      - Populated if an error occurs.
//
// Returns a newly created GTDiff, or nil if an error occurred.
+ (GTDiff *)diffWorkingDirectoryToHEADInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error;

// Designated initialiser.
//
// diff       - The diff to represent. Cannot be NULL.
// repository - The repository in which the diff lives. Cannot be nil.
//
// Returns the initialized object.
- (instancetype)initWithGitDiff:(git_diff *)diff repository:(GTRepository *)repository;

// The libgit2 diff object.
- (git_diff *)git_diff __attribute__((objc_returns_inner_pointer));

// The number of deltas of the given type that are contained in the diff.
- (NSUInteger)numberOfDeltasWithType:(GTDiffDeltaType)deltaType;

// Enumerate the deltas in a diff.
//
// It is worth noting that the `git_diff_patch` objects backing each delta
// contain the entire contents in memory. It is therefore recommended you
// do not store the `delta` object given here, but instead perform any work
// necessary within the provided block.
//
// Also note that this method blocks during the enumeration.
//
// block - A block to be executed for each delta. Setting `stop` to `YES`
//         immediately stops the enumeration.
- (void)enumerateDeltasUsingBlock:(void (^)(GTDiffDelta *delta, BOOL *stop))block;

// Modify the diff list to combine similar changes using the given options.
//
// options - A dictionary containing any of the above find options key constants
//           or nil to use the defaults.
- (void)findSimilarWithOptions:(NSDictionary *)options;

// Merge a diff with another diff.
//
// diff  - the diff to merge in.
// error - Populated if an error occurs
//
// Returns YES if the merge was successfull, and NO and sets `error` otherwise.
- (BOOL)mergeDiffWithDiff:(GTDiff *)diff error:(NSError **)error;

@end
