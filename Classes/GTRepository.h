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

#import <git2.h>
#import "GTWalker.h"
#import "GTReference.h"


@class GTWalker;
@class GTObject;
@class GTOdbObject;
@class GTCommit;
@class GTIndex;
@class GTBranch;

@interface GTRepository : NSObject {}

@property (nonatomic, assign, readonly) git_repository *repo;
@property (nonatomic, retain, readonly) NSURL *fileUrl;
@property (nonatomic, retain, readonly) GTWalker *walker;
@property (nonatomic, retain, readonly) GTIndex *index;

// Convenience initializers
- (id)initByOpeningRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error;
+ (id)repoByOpeningRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error;

- (id)initByCreatingRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error;
+ (id)repoByCreatingRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error;

// Helper for getting the sha1 has of a raw object
//
// data - the data to compute a sha1 hash for
// error(out) - will be filled if an error occurs
//
// returns the sha1 for the raw object or nil if there was an error
+ (NSString *)hash:(NSString *)data type:(GTObjectType)type error:(NSError **)error;

// Lookup objects in the repo by oid or sha1
- (GTObject *)lookupByOid:(git_oid *)oid type:(GTObjectType)type error:(NSError **)error;
- (GTObject *)lookupByOid:(git_oid *)oid error:(NSError **)error;
- (GTObject *)lookupBySha:(NSString *)sha type:(GTObjectType)type error:(NSError **)error;
- (GTObject *)lookupBySha:(NSString *)sha error:(NSError **)error;

// Check to see if objects exist in the repo
- (BOOL)exists:(NSString *)sha error:(NSError **)error;
- (BOOL)hasObject:(NSString *)sha error:(NSError **)error;

- (GTOdbObject *)rawRead:(const git_oid *)oid error:(NSError **)error;
- (GTOdbObject *)read:(NSString *)sha error:(NSError **)error;

- (NSString *)write:(NSString *)data type:(GTObjectType)type error:(NSError **)error;

- (BOOL)walk:(NSString *)sha sorting:(GTWalkerOptions)sortMode error:(NSError **)error block:(void (^)(GTCommit *commit, BOOL *stop))block;
- (BOOL)walk:(NSString *)sha error:(NSError **)error block:(void (^)(GTCommit *commit, BOOL *stop))block;
- (NSArray *)selectCommitsStartingFrom:(NSString *)sha error:(NSError **)error block:(BOOL (^)(GTCommit *commit, BOOL *stop))block;

- (BOOL)setupIndexAndReturnError:(NSError **)error;

- (GTReference *)headAndReturnError:(NSError **)error;

// Convenience methods to return references in this repository (see GTReference.h)
- (NSArray *)listReferenceNamesOfTypes:(GTReferenceTypes)types error:(NSError **)error;
- (NSArray *)listAllReferenceNamesAndReturnError:(NSError **)error;

// Convenience methods to return branches in the repository
- (NSArray *)listAllBranchesAndReturnError:(NSError **)error;

// Count all commits in the current branch (HEAD)
//
// error(out) - will be filled if an error occurs
//
// returns number of commits in the current branch or NSNotFound if an error occurred
- (NSInteger)numberOfCommitsInCurrentBranchAndReturnError:(NSError **)error;

- (GTBranch *)createBranchFrom:(GTReference *)ref named:(NSString *)name error:(NSError **)error;
	
@end
