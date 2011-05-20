//
//  GTWalker.h
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

#import <git2.h>
#import "GTObject.h"


// Options to specify enumeration order when walking through a repository.
// These options may be bitwise-OR'd together
enum {
	GTWalkerOptionsNone = GIT_SORT_NONE,
	GTWalkerOptionsTopologicalSort = GIT_SORT_TOPOLOGICAL, // sort parents before children
	GTWalkerOptionsTimeSort = GIT_SORT_TIME, // sort by commit time
	GTWalkerOptionsReverse = GIT_SORT_REVERSE, // sort in reverse order
};

typedef NSInteger GTWalkerOptions;

@class GTRepository;
@class GTCommit;
@protocol GTObject;

// This object is usually used from within a repository. You generally don't 
// need to instantiate a GTWalker. Instead, use the walker property on 
// GTRepository
@interface GTWalker : NSObject <GTObject> {}

@property (nonatomic, assign) GTRepository *repository;

- (id)initWithRepository:(GTRepository *)theRepo error:(NSError **)error;
+ (id)walkerWithRepository:(GTRepository *)theRepo error:(NSError **)error;

- (BOOL)push:(NSString *)sha error:(NSError **)error;

// suppress the enumeration of the specified commit and all of its ancestors
- (BOOL)skipCommitWithHash:(NSString *)sha error:(NSError **)error;

- (void)reset;
- (void)setSortingOptions:(GTWalkerOptions)options;
- (GTCommit *)next;
- (NSInteger)countFromSha:(NSString *)sha error:(NSError **)error;

@end
