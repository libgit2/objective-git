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

// Enumerates the commits in a repository.
@interface GTEnumerator : NSEnumerator

// The repository being enumerated.
@property (nonatomic, strong, readonly) GTRepository *repository;

// The options currently being used for enumeration.
//
// To set new options, use -resetWithOptions:.
@property (nonatomic, assign, readonly) GTEnumeratorOptions options;

// Initializes the receiver to enumerate the commits in the given repository.
//
// repo  - The repository to enumerate the commits of. This must not be nil.
// error - If not NULL, set to any error that occurs.
//
// Returns an initialized enumerator, or nil if an error occurs.
- (id)initWithRepository:(GTRepository *)repo error:(NSError **)error;

// Marks a commit to start traversal from.
//
// sha   - The SHA of a commit in the receiver's repository. This must not be
//         nil.
// error - If not NULL, this will be set to any error that occurs.
//
// Returns whether pushing the commit was successful.
- (BOOL)pushSHA:(NSString *)sha error:(NSError **)error;

// Pushes all references matching `refGlob`.
//
// refGlob - A glob to match references against. This must not be nil.
// error   - If not NULL, this will be set to any error that occurs.
//
// Returns whether pushing matching references was successful.
- (BOOL)pushGlob:(NSString *)refGlob error:(NSError **)error;

// Hides the specified commit and all of its ancestors when enumerating.
//
// sha   - The SHA of a commit in the receiver's repository. This must not be
//         nil.
// error - If not NULL, this will be set to any error that occurs.
//
// Returns whether marking the SHA for hiding was successful.
- (BOOL)hideSHA:(NSString *)sha error:(NSError **)error;

// Hides all references matching `refGlob`.
//
// refGlob - A glob to match references against. This must not be nil.
// error   - If not NULL, this will be set to any error that occurs.
//
// Returns whether marking matching references for hiding was successful.
- (BOOL)hideGlob:(NSString *)refGlob error:(NSError **)error;

// Resets the receiver, putting it back into a clean state for reuse, and
// replacing the receiver's `options`.
- (void)resetWithOptions:(GTEnumeratorOptions)options;

// Enumerates all marked commits, completely exhausting the receiver.
//
// error - If not NULL, set to any error that occurs during traversal.
//
// Returns a (possibly empty) array of GTCommits, or nil if an error occurs.
- (NSArray *)allObjectsWithError:(NSError **)error;

// Gets the next commit.
//
// success - If not NULL, this will be set to whether getting the next object
//           was successful. This will be YES if the receiver is exhausted, so
//           it can be used to interpret the meaning of a nil return value.
// error   - If not NULL, set to any error that occurs during traversal.
//
// Returns nil if an error occurs or the receiver is exhausted.
- (GTCommit *)nextObjectWithSuccess:(BOOL *)success error:(NSError **)error;

// Counts the number of commits that were not enumerated, completely exhausting
// the receiver.
//
// error - If not NULL, set to any error that occurs during traversal.
//
// Returns the number of commits remaining, or `NSNotFound` if an error occurs.
- (NSUInteger)countRemainingObjects:(NSError **)error;

@end
