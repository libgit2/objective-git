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

@interface GTBranch : NSObject <GTObject> {}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *shortName;
@property (nonatomic, readonly) NSString *sha;
@property (nonatomic, readonly) NSString *remoteName;
@property (nonatomic, readonly) GTBranchType branchType;
@property (nonatomic, readonly, dct_weak) GTRepository *repository;
@property (nonatomic, readonly, strong) GTReference *reference;
@property (nonatomic, copy) NSArray *remoteBranches;

+ (NSString *)localNamePrefix;
+ (NSString *)remoteNamePrefix;

// Convenience initializers
- (id)initWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error;
+ (id)branchWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error;

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

// Find the remote branch for the passed in remote name.
//
// returns the matched remote branch or nil if no match was found.
- (GTBranch *)remoteBranchForRemoteName:(NSString *)remote;

@end
