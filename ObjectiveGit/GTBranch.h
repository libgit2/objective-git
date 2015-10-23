//
//  GTBranch.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/3/11.
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

@class GTCommit;
@class GTReference;
@class GTRemote;
@class GTRepository;

typedef NS_ENUM(NSInteger, GTBranchType) {
    GTBranchTypeLocal = GIT_BRANCH_LOCAL,
    GTBranchTypeRemote = GIT_BRANCH_REMOTE,
};

NS_ASSUME_NONNULL_BEGIN

/// A git branch object.
///
/// Branches are considered to be equivalent if both their `name` and `SHA` are
/// equal.
@interface GTBranch : NSObject

@property (nonatomic, readonly, nullable) NSString *name;
@property (nonatomic, readonly, nullable) NSString *shortName;
@property (nonatomic, copy, readonly, nullable) GTOID *OID;
@property (nonatomic, readonly, nullable) NSString *remoteName;
@property (nonatomic, readonly) GTBranchType branchType;
@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly, strong) GTReference *reference;

+ (NSString *)localNamePrefix;
+ (NSString *)remoteNamePrefix;

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer.
///
/// ref  - The branch reference to wrap. Must not be nil.
/// repo - The repository containing the branch. Must not be nil.
///
/// Returns the initialized receiver.
- (nullable instancetype)initWithReference:(GTReference *)ref repository:(GTRepository *)repo NS_DESIGNATED_INITIALIZER;

/// Convenience class initializer.
///
/// ref  - The branch reference to wrap. Must not be nil.
/// repo - The repository containing the branch. Must not be nil.
///
/// Returns an initialized instance.
+ (nullable instancetype)branchWithReference:(GTReference *)ref repository:(GTRepository *)repo;

/// Get the target commit for this branch
///
/// error(out) - will be filled if an error occurs
///
/// returns a GTCommit object or nil if an error occurred
- (nullable GTCommit *)targetCommitWithError:(NSError **)error;

/// Count all commits in this branch
///
/// error(out) - will be filled if an error occurs
///
/// returns number of commits in the branch or NSNotFound if an error occurred
- (NSUInteger)numberOfCommitsWithError:(NSError **)error;

/// Get unique commits
///
/// otherBranch -
/// error       - If not NULL, set to any error that occurs.
///
/// Returns a (possibly empty) array of GTCommits, or nil if an error occurs.
- (nullable NSArray<GTCommit *> *)uniqueCommitsRelativeToBranch:(GTBranch *)otherBranch error:(NSError **)error;

/// Deletes the local branch and nils out the reference.
- (BOOL)deleteWithError:(NSError **)error;

/// If the receiver is a local branch, looks up and returns its tracking branch.
/// If the receiver is a remote branch, returns self. If no tracking branch was
/// found, returns nil and sets `success` to YES.
- (nullable GTBranch *)trackingBranchWithError:(NSError **)error success:(nullable BOOL *)success;

/// Update the tracking branch.
///
/// trackingBranch - The tracking branch for the receiver. If nil, it unsets the
///                  tracking branch.
/// error          - The error if one occurred.
///
/// Returns whether it was successful.
- (BOOL)updateTrackingBranch:(nullable GTBranch *)trackingBranch error:(NSError **)error;

/// Reloads the branch's reference and creates a new branch based off that newly
/// loaded reference.
///
/// This does *not* change the receiver.
///
/// error - The error if one occurred.
///
/// Returns the reloaded branch, or nil if an error occurred.
- (nullable GTBranch *)reloadedBranchWithError:(NSError **)error;

/// Calculate the ahead/behind count from this branch to the given branch.
///
/// ahead  - The number of commits which are unique to the receiver. Cannot be
///          NULL.
/// behind - The number of commits which are unique to `branch`. Cannot be NULL.
/// branch - The branch to which the receiver should be compared.
/// error  - The error if one occurs.
///
/// Returns whether the calculation was successful.
- (BOOL)calculateAhead:(size_t *)ahead behind:(size_t *)behind relativeTo:(GTBranch *)branch error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
