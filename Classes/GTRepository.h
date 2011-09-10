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

@interface GTRepository : NSObject <GTObject> {}

@property (nonatomic, assign, readonly) git_repository *repo;
@property (nonatomic, strong, readonly) NSURL *fileUrl;
@property (nonatomic, strong, readonly) GTEnumerator *enumerator; // should only be used on the main thread
@property (nonatomic, strong, readonly) GTIndex *index;
@property (nonatomic, strong, readonly) GTObjectDatabase *objectDatabase;

+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL error:(NSError **)error;

+ (id)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error;
- (id)initWithURL:(NSURL *)localFileURL error:(NSError **)error;

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

// Enumerate the commits in the repo with a default sortOption of GTEnumeratorOptionsTimeSort
- (BOOL)enumerateCommitsBeginningAtSha:(NSString *)sha sortOptions:(GTEnumeratorOptions)options error:(NSError **)error usingBlock:(void (^)(GTCommit *commit, BOOL *stop))block;
- (BOOL)enumerateCommitsBeginningAtSha:(NSString *)sha error:(NSError **)error usingBlock:(void (^)(GTCommit *commit, BOOL *stop))block;

// filter enumerated commits in the repo with a default sort option of GTEnumeratorOptionsTimeSort
- (NSArray *)selectCommitsBeginningAtSha:(NSString *)sha error:(NSError **)error block:(BOOL (^)(GTCommit *commit, BOOL *stop))block;
- (NSArray *)selectCommitsBeginningAtSha:(NSString *)sha sortOptions:(GTEnumeratorOptions)options error:(NSError **)error block:(BOOL (^)(GTCommit *commit, BOOL *stop))block;


- (BOOL)setupIndexWithError:(NSError **)error;

- (GTReference *)headReferenceWithError:(NSError **)error;

// Convenience methods to return references in this repository (see GTReference.h)
- (NSArray *)allReferenceNamesOfTypes:(GTReferenceTypes)types error:(NSError **)error;
- (NSArray *)allReferenceNamesWithError:(NSError **)error;

// Convenience methods to return branches in the repository
- (NSArray *)allBranchesWithError:(NSError **)error;

// Count all commits in the current branch (HEAD)
//
// error(out) - will be filled if an error occurs
//
// returns number of commits in the current branch or NSNotFound if an error occurred
- (NSInteger)numberOfCommitsInCurrentBranch:(NSError **)error;

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

// Is this repository empty? This will only be the case in a freshly `git init`'d repository.
//
// returns whether this repository is empty
- (BOOL)isEmpty;

// Find the commits that are on our local branch but not on the remote branch.
//
// error(out) - will be filled if an error occurs
//
// returns the local commits, an empty array if there is no remote branch, or nil if an error occurred
- (NSArray *)localCommitsRelativeToRemoteBranch:(GTBranch *)remoteBranch error:(NSError **)error;
	
@end
