//
//  GTWalker.m
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

#import "GTWalker.h"
#import "GTCommit.h"
#import "NSError+Git.h"
#import "GTRepository.h"


@interface GTWalker()

@property (nonatomic, assign) git_revwalk *walk;

@end


@implementation GTWalker

@synthesize repo;
@synthesize walk;

- (id)initWithRepository:(GTRepository *)theRepo error:(NSError **)error {
	
	if(self = [super init]){
	
		self.repo = theRepo;
		git_revwalk *w;
		int gitError = git_revwalk_new(&w, self.repo.repo);
		if(gitError != GIT_SUCCESS) {
			if (error != NULL)
				*error = [NSError gitErrorForInitRevWalker:gitError];
			return nil;
		}
		self.walk = w;
	}
	return self;
}

- (BOOL)push:(NSString *)sha error:(NSError **)error {
	
	git_commit *commit;
	commit = (git_commit *)[GTObject getNewObjectInRepo:self.repo.repo sha:sha type:GIT_OBJ_COMMIT error:error];
	if(commit == nil) return NO;
	
	git_revwalk_push(self.walk, commit);
	return YES;
}

- (BOOL)hide:(NSString *)sha error:(NSError **)error {
	
	git_commit *commit;
	commit = (git_commit *)[GTObject getNewObjectInRepo:self.repo.repo sha:sha type:GIT_OBJ_COMMIT error:error];
	if(commit == nil) return NO;
	
	git_revwalk_hide(self.walk, commit);
	return YES;
}

- (void)reset {
	
	git_revwalk_reset(self.walk);
}

- (void)setSortingOptions:(GTWalkerOptions)options {
	git_revwalk_sorting(self.walk, options);
}

- (GTCommit *)next {

	git_commit *commit;
	int gitError = git_revwalk_next(&commit, self.walk);
	if(gitError == GIT_EREVWALKOVER)
		return nil;
	
	return (GTCommit *)[GTObject objectInRepo:self.repo withObject:(git_object*)commit];
}

//- (void)walkCommitsUsingBlock:(void (^)(GTCommit *commit, BOOL *stop))block {
//	GTCommit *currentCommit = nil;
//	BOOL stop = NO;
//	while((currentCommit = [self next])) {
//		block(currentCommit, &stop);
//		if(stop) break;
//	}
//}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	
	git_revwalk_free(self.walk);
	self.repo = nil;
	[super dealloc];
}


@end
