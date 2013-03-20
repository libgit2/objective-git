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
typedef enum : git_diff_option_t {
	GTDiffOptionsFlagsNormal = GIT_DIFF_NORMAL,
	GTDiffOptionsFlagsReverse = GIT_DIFF_REVERSE,
	GTDiffOptionsFlagsForceText = GIT_DIFF_FORCE_TEXT,
	GTDiffOptionsFlagsIgnoreWhitespace = GIT_DIFF_IGNORE_WHITESPACE,
	GTDiffOptionsFlagsIgnoreWhitespaceChange = GIT_DIFF_IGNORE_WHITESPACE_CHANGE,
	GTDiffOptionsFlagsIgnoreWhitespaceEOL = GIT_DIFF_IGNORE_WHITESPACE_EOL,
	GTDiffOptionsFlagsIgnoreSubmodules = GIT_DIFF_IGNORE_SUBMODULES,
	GTDiffOptionsFlagsPatience = GIT_DIFF_PATIENCE,
	GTDiffOptionsFlagsIncludeIgnored = GIT_DIFF_INCLUDE_IGNORED,
	GTDiffOptionsFlagsIncludeUntracked = GIT_DIFF_INCLUDE_UNTRACKED,
	GTDiffOptionsFlagsIncludeUnmodified = GIT_DIFF_INCLUDE_UNMODIFIED,
	GTDiffOptionsFlagsRecurseUntrackedDirs = GIT_DIFF_RECURSE_UNTRACKED_DIRS,
	GTDiffOptionsFlagsDisablePathspecMatch = GIT_DIFF_DISABLE_PATHSPEC_MATCH,
	GTDiffOptionsFlagsDeltasAreICase = GIT_DIFF_DELTAS_ARE_ICASE,
	GTDiffOptionsFlagsIncludeUntrackedContent = GIT_DIFF_INCLUDE_UNTRACKED_CONTENT,
	GTDiffOptionsFlagsSkipBinaryCheck = GIT_DIFF_SKIP_BINARY_CHECK,
	GTDiffOptionsFlagsIncludeTypeChange = GIT_DIFF_INCLUDE_TYPECHANGE,
	GTDiffOptionsFlagsIncludeTypeChangeTrees = GIT_DIFF_INCLUDE_TYPECHANGE_TREES,
	GTDiffOptionsFlagsIgnoreFileMode = GIT_DIFF_IGNORE_FILEMODE,
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
extern NSString *const GTDiffFindOptionsTargetLimitKey;

// Enum for options passed into `-findSimilarWithOptions:`.
//
// For individual case documentation see `diff.h`.
typedef enum : git_diff_find_t {
	GTDiffFindOptionsFlagsFindRenames = GIT_DIFF_FIND_RENAMES,
	GTDiffFindOptionsFlagsFindRenamesFromRewrites = GIT_DIFF_FIND_RENAMES_FROM_REWRITES,
	GTDiffFindOptionsFlagsFindCopies = GIT_DIFF_FIND_COPIES,
	GTDiffFindOptionsFlagsFindCopiesFromUnmodified = GIT_DIFF_FIND_COPIES_FROM_UNMODIFIED,
	GTDiffFindOptionsFlagsFindAndBreakRewrites = GIT_DIFF_FIND_AND_BREAK_REWRITES,
} GTDiffFindOptionsFlags;

// A class representing a single "diff".
//
// Analagous to `git_diff_list` in libgit2, this object represents a list of
// changes or "deltas", which are represented by `GTDiffDelta` objects.
@interface GTDiff : NSObject

// The libgit2 diff list object.
@property (nonatomic, readonly) git_diff_list *git_diff_list;

// The number of deltas represented by the diff object.
@property (nonatomic, readonly) NSUInteger deltaCount;

// Create a diff between 2 `GTTree`s.
//
// The 2 trees must be from the same repository, or an exception will be thrown.
//
// oldTree - The "left" side of the diff.
// newTree - The "right" side of the diff.
// options - A dictionary containing any of the above options key constants, or
//           nil to use the defaults.
// error   - Populated with an `NSError` object on error, if information is
//           available.
//
// Returns a newly created `GTDiff` object or nil on error.
+ (GTDiff *)diffOldTree:(GTTree *)oldTree withNewTree:(GTTree *)newTree options:(NSDictionary *)options error:(NSError **)error;

// Create a diff between a repository's current index.
//
// This is equivalent to `git diff --cached <treeish>` or if you pass the HEAD
// tree, then `git diff --cached`.
//
// The tree you pass will be used for the "left" side of the diff, and the
// index will be used for the "right" side of the diff.
//
// tree    - The tree to be diffed. The index will be taken from this tree's
//           repository. The left side of the diff.
// options - A dictionary containing any of the above options key constants, or
//           nil to use the defaults.
// error   - Populated with an `NSError` object on error, if information is
//           available.
//
// Returns a newly created `GTDiff` object or nil on error.
+ (GTDiff *)diffIndexFromTree:(GTTree *)tree options:(NSDictionary *)options error:(NSError **)error;

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
// tree    - The tree to be diffed. The tree will be the left side of the diff.
// options - A dictionary containing any of the above options key constants, or
//           nil to use the defaults.
// error   - Populated with an `NSError` object on error, if information is
//           available.
//
// Returns a newly created `GTDiff` object or nil on error.
+ (GTDiff *)diffWorkingDirectoryFromTree:(GTTree *)tree options:(NSDictionary *)options error:(NSError **)error;

// Create a diff between the working directory and HEAD.
//
// repository - The repository to be used for the diff.
// options    - A dictionary containing any of the above options key constants,
//              or nil to use the defaults.
// error      - Populated if an error occurs.
//
// Returns a newly created GTDiff, or nil if an error occurred.
+ (GTDiff *)diffWorkingDirectoryToHEADInRepository:(GTRepository *)repository options:(NSDictionary *)options error:(NSError **)error;

// Designated initialiser.
- (instancetype)initWithGitDiffList:(git_diff_list *)diffList;

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

@end
