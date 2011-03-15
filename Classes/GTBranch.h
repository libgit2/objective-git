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

@class GTCommit;
@class GTReference;
@class GTRepository;

@interface GTBranch : NSObject {}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *shortName;
@property (nonatomic, readonly) NSString *sha;
@property (nonatomic, readonly, assign) GTRepository *repository;
@property (nonatomic, readonly, assign) GTReference *reference;

// Convenience initializers
- (id)initWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error;
+ (id)branchWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error;

- (id)initWithReference:(GTReference *)ref repository:(GTRepository *)repo;
+ (id)branchWithReference:(GTReference *)ref repository:(GTRepository *)repo;

+ (id)branchFromCurrentBranchInRepository:(GTRepository *)repo error:(NSError **)error;

// Get the target commit for this branch
// 
// error(out) - will be filled if an error occurs
// 
// returns a GTCommit object or nil if an error occurred
- (GTCommit *)targetCommitAndReturnError:(NSError **)error;

// List all branches in a repository
//
// error(out) - will be filled if an error occurs
//
// returns an NSArray of GTBranch objects or nil if an error occurred
+ (NSArray *)listAllBranchesInRepository:(GTRepository *)repo error:(NSError **)error;

// Count all commits in this branch
//
// error(out) - will be filled if an error occurs
//
// returns number of commits in the branch or NSNotFound if an error occurred
- (NSInteger)numberOfCommitsAndReturnError:(NSError **)error;

@end
