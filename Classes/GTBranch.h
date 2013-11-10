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
    GTBranchTypeLocal = 1,
    GTBranchTypeRemote
} GTBranchType;

@interface GTBranch : NSObject

@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly, strong) GTReference *reference;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *shortName;
@property (nonatomic, readonly) NSString *remoteName;
@property (nonatomic, readonly) NSString *SHA;
@property (nonatomic, readonly) GTBranchType branchType;
@property (nonatomic) GTBranch *upstreamBranch;

+ (NSString *)localNamePrefix;
+ (NSString *)remoteNamePrefix;

// Lookup a branch by name.
//
// name       - The branch name to lookup.
// repository - The repository to lookup the branch in.
// error      - A pointer which will point to a valid error if the lookup fails.
//
// Returns the branch object with that name, or nil if an error occurred.
+ (instancetype)branchByLookingUpBranchNamed:(NSString *)name inRepository:(GTRepository *)repository error:(NSError **)error;

// Create a branch from a name and target.
//
// name       - The name of the branch to create.
// commit     - The commit the branch should point to.
// force      - If set to YES, a branch with same name would be deleted.
// repository - The repository to create the branch in.
// error      - A pointer which will point to a valid error if the creation fails.
//
// Returns a newly created branch object, or nil if the branch couldn't be created.
+ (instancetype)branchByCreatingBranchNamed:(NSString *)name target:(GTCommit *)commit force:(BOOL)force inRepository:(GTRepository *)repository error:(NSError **)error;

// Convenience initializers
+ (id)branchWithReferenceNamed:(NSString *)referenceName inRepository:(GTRepository *)repo error:(NSError **)error;
+ (id)branchWithReference:(GTReference *)ref;

// Designated initializer
- (id)initWithReference:(GTReference *)ref;

// Get the target commit for this branch
// 
// error - A pointer which will point to a valid error if the target can't be found.
// 
// Returns a GTCommit object or nil if an error occurred.
- (GTCommit *)targetCommitAndReturnError:(NSError **)error;

// Deletes the local branch and nils out the reference.
- (BOOL)deleteWithError:(NSError **)error;


// Reloads the branch's reference and creates a new branch based off that newly
// loaded reference.
//
// This does *not* change the receiver.
//
// error - The error if one occurred.
//
// Returns the reloaded branch, or nil if an error occurred.
- (GTBranch *)reloadedBranchWithError:(NSError **)error;

// If the receiver is a local branch, looks up and returns its tracking branch.
// If the receiver is a remote branch, returns self. If no tracking branch was
// found, returns nil and sets `success` to YES.
- (GTBranch *)trackingBranchWithError:(NSError **)error success:(BOOL *)success;

// Count all commits in this branch
//
// error - will be filled if an error occurs
//
// Returns the number of commits in the receiver or `NSNotFound` if an error occurred
- (NSUInteger)numberOfCommitsWithError:(NSError **)error;

// Get the unique commits between branches.
//
// This method returns an array representing the unique commits
// that exist between the receiver and `otherBranch`.
//
// otherBranch - The branch to compare against.
// error       - Will be set if an error occurs.
//
// Returns an array of GTCommits, or nil if an error occurred.
- (NSArray *)uniqueCommitsRelativeToBranch:(GTBranch *)otherBranch error:(NSError **)error;

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
