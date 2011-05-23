//
//  GTEnumerator.m
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

#import "GTEnumerator.h"
#import "GTCommit.h"
#import "GTLib.h"
#import "NSError+Git.h"
#import "GTRepository.h"


@interface GTEnumerator()
@property (nonatomic, assign) git_revwalk *walk;
@end

@implementation GTEnumerator

- (void)dealloc {
	
	git_revwalk_free(self.walk);
	self.repository = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark API

@synthesize repository;
@synthesize walk;
@synthesize options;

- (id)initWithRepository:(GTRepository *)theRepo error:(NSError **)error {
	
	if((self = [super init])) {
		self.repository = theRepo;
		git_revwalk *w;
		int gitError = git_revwalk_new(&w, self.repository.repo);
		if(gitError != GIT_SUCCESS) {
			if (error != NULL)
				*error = [NSError gitErrorForInitRevWalker:gitError];
            [self release];
			return nil;
		}
		self.walk = w;
	}
	return self;
}
+ (id)enumeratorWithRepository:(GTRepository *)theRepo error:(NSError **)error {
	
	return [[[self alloc] initWithRepository:theRepo error:error] autorelease];
}

- (BOOL)push:(NSString *)sha error:(NSError **)error {
	
	git_oid oid;
	BOOL success = [GTLib convertSha:sha toOid:&oid error:error];
	if(!success)return NO;
	
	[self reset];
	
	int gitError = git_revwalk_push(self.walk, &oid);
	if(gitError != GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError gitErrorForPushRevWalker:gitError];
		return NO;
	}
	
	return YES;
}

- (BOOL)skipCommitWithHash:(NSString *)sha error:(NSError **)error {
	
	git_oid oid;
	BOOL success = [GTLib convertSha:sha toOid:&oid error:error];
	if(!success)return NO;
	
	int gitError = git_revwalk_hide(self.walk, &oid);
	if(gitError != GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError gitErrorForHideRevWalker:gitError];
		return NO;
	}
	return YES;
}

- (void)reset {
	
	git_revwalk_reset(self.walk);
}

- (void)setOptions:(GTEnumeratorOptions)newOptions {
    options = newOptions;
	git_revwalk_sorting(self.walk, (unsigned int)options);
}

- (id)nextObject {
	
	git_oid oid;
	int gitError = git_revwalk_next(&oid, self.walk);
	if(gitError == GIT_EREVWALKOVER)
		return nil;
	
	// ignore error if we can't lookup object and just return nil
	return [self.repository lookupObjectBySha:[GTLib convertOidToSha:&oid] objectType:GTObjectTypeCommit error:nil];
}

- (NSArray *)allObjects {

    NSMutableArray *array = [NSMutableArray array];
    id object = nil;
    while ((object = [self nextObject]) != nil) {
        [array addObject:object];
    }
    return array;
}

- (NSInteger)countFromSha:(NSString *)sha error:(NSError **)error {
	
	[self setOptions:GTEnumeratorOptionsNone];
	
	BOOL success = [self push:sha error:error];
	if(!success) return NSNotFound;
	
	git_oid oid;
	NSUInteger count = 0;
	while(git_revwalk_next(&oid, self.walk) == GIT_SUCCESS) {
		count++;
	}
	return count;
}

@end
