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
@class GTRepository;

typedef enum {
    GTBranchTypeLocal = GIT_BRANCH_LOCAL,
    GTBranchTypeRemote = GIT_BRANCH_REMOTE,
} GTBranchType;

/// A git branch object.
///
/// Branches are considered to be equivalent iff both their `name` and `SHA` are
/// equal.
@interface GTBranch : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *shortName;
@property (nonatomic, readonly) NSString *SHA;
@property (nonatomic, readonly) NSString *remoteName;
@property (nonatomic, readonly) GTBranchType branchType;
@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly, strong) GTReference *reference;

+ (NSString *)localNamePrefix;
+ (NSString *)remoteNamePrefix;

- (id)initWithReference:(GTReference *)ref repository:(GTRepository *)repo;
+ (id)branchWithReference:(GTReference *)ref repository:(GTRepository *)repo;

// Get the target commit for this branch
// 
// error(out) - will be filled if an error occurs
// 
// returns a GTCommit object or nil if an error occurred
- (GTCommit *)targetCommitAndReturnError:(NSError **)error;

// Count all commits in this branch
//
// error(out) - will be filled if an error occurs
//
// returns number of commits in the branch or NSNotFound if an error occurred
- (NSUInteger)numberOfCommitsWithError:(NSError **)error;

- (NSArray *)uniqueCommitsRelativeToBranch:(GTBranch *)otherBranch error:(NSError **)error;

// Deletes the local branch and nils out the reference.
- (BOOL)deleteWithError:(NSError **)error;

// If the receiver is a local branch, looks up and returns its tracking branch.
// If the receiver is a remote branch, returns self. If no tracking branch was
// found, returns nil and sets `success` to YES.
- (GTBranch *)trackingBranchWithError:(NSError **)error success:(BOOL *)success;

// Reloads the branch's reference and creates a new branch based off that newly
// loaded reference.
//
// This does *not* change the receiver.
//
// error - The error if one occurred.
//
// Returns the reloaded branch, or nil if an error occurred.
- (GTBranch *)reloadedBranchWithError:(NSError **)error;

// Calculate the ahead/behind count from this branch to the given branch.
//
// ahead  - The number of commits which are unique to the receiver. Cannot be
//          NULL.
// behind - The number of commits which are unique to `branch`. Cannot be NULL.
// branch - The branch to which the receiver should be compared.
// error  - The error if one occurs.
//
// Returns whether the calculation was successful.
- (BOOL)calculateAhead:(size_t *)ahead behind:(size_t *)behind relativeTo:(GTBranch *)branch error:(NSError **)error;

@end
