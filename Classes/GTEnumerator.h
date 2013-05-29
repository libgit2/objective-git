//
//  GTEnumerator.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/21/11.
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

// Options to specify enumeration order when enumerating through a repository.
// With the exception of GTEnumeratorOptionsNone, the values here can be ORed
// together to combine their behaviors.
//
// GTEnumeratorOptionsNone            - Implementation-defined sorting.
// GTEnumeratorOptionsTopologicalSort - Sort parents before children.
// GTEnumeratorOptionsTimeSort        - Sort by commit time.
// GTEnumeratorOptionsReverse         - Iterate in reverse order.
typedef enum : unsigned int {
	GTEnumeratorOptionsNone = GIT_SORT_NONE,
	GTEnumeratorOptionsTopologicalSort = GIT_SORT_TOPOLOGICAL,
	GTEnumeratorOptionsTimeSort = GIT_SORT_TIME,
	GTEnumeratorOptionsReverse = GIT_SORT_REVERSE,
} GTEnumeratorOptions;

@class GTRepository;
@class GTCommit;
@protocol GTObject;

// Enumerates the commits in a repository. You generally don't need to
// instantiate a GTEnumerator -- use GTRepository.enumerator instead.
@interface GTEnumerator : NSEnumerator <GTObject>

// The repository being enumerated.
@property (nonatomic, weak, readonly) GTRepository *repository;

// The options to use when enumerating.
@property (nonatomic, assign) GTEnumeratorOptions options;

// Initializes the receiver to enumerate the commits in `theRepo`.
- (id)initWithRepository:(GTRepository *)theRepo error:(NSError **)error;

// Creates an enumerator for the commits in `theRepo`.
+ (id)enumeratorWithRepository:(GTRepository *)theRepo error:(NSError **)error;

// Marks a commit to start traversal from.
//
// sha   - The SHA of a commit in the receiver's repository.
// error - If not NULL, this will be set to any error that occurs.
//
// Returns whether pushing the commit was successful.
- (BOOL)pushSHA:(NSString *)sha error:(NSError **)error;

// Skips the specified commit and all of its ancestors when enumerating.
//
// sha   - The SHA of a commit in the receiver's repository.
// error - If not NULL, this will be set to any error that occurs.
//
// Returns whether marking the SHA for skipping was successful.
- (BOOL)skipSHA:(NSString *)sha error:(NSError **)error;

// Resets the receiver, putting it back into a clean state for reuse.
- (void)reset;

// Enumerates all marked commits, completely exhausting the receiver.
//
// error - If not NULL, set to any error that occurs during traversal.
//
// Returns an array of GTCommits, or nil if an error occurs.
- (NSArray *)allObjectsWithError:(NSError **)error;

// Gets the next commit.
//
// error - If not NULL, set to any error that occurs during traversal.
//
// Returns nil if an error occurs or the receiver is exhausted.
- (GTCommit *)nextObjectWithError:(NSError **)error;

// Counts the number of commits that were not enumerated, completely exhausting
// the receiver.
//
// error - If not NULL, set to any error that occurs during traversal.
//
// Returns the number of commits remaining, or `NSNotFound` if an error occurs.
- (NSUInteger)countRemainingObjectsWithError:(NSError **)error;

@end
