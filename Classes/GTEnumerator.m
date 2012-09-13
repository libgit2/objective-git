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
#import "NSError+Git.h"
#import "NSString+Git.h"
#import "GTRepository.h"
#import "GTRepository+Private.h"

@interface GTEnumerator()
@property (nonatomic, assign) git_revwalk *walk;

- (void)cleanup;
@end


@implementation GTEnumerator

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> repository: %@", NSStringFromClass([self class]), self, self.repository];
}

- (void)dealloc {
	[self cleanup];
}


#pragma mark API

@synthesize repository;
@synthesize walk;
@synthesize options;

- (id)initWithRepository:(GTRepository *)theRepo error:(NSError **)error {
	if((self = [super init])) {
		self.repository = theRepo;
		git_revwalk *w;
		int gitError = git_revwalk_new(&w, self.repository.git_repository);
		if(gitError < GIT_OK) {
			if (error != NULL)
				*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to initialize rev walker."];
			return nil;
		}
		self.walk = w;
	}
	return self;
}

+ (id)enumeratorWithRepository:(GTRepository *)theRepo error:(NSError **)error {
	return [[self alloc] initWithRepository:theRepo error:error];
}

- (void)cleanup {
	[self.repository removeEnumerator:self];
	self.repository = nil;
	
	if(self.walk != NULL) {
		git_revwalk_free(self.walk);
		self.walk = NULL;
	}
}

- (BOOL)push:(NSString *)sha error:(NSError **)error {
	git_oid oid;
	BOOL success = [sha git_getOid:&oid error:error];
	if(!success) return NO;
	
	[self reset];
	
	int gitError = git_revwalk_push(self.walk, &oid);
	if(gitError < GIT_OK) {
		if (error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to push sha onto rev walker."];
		return NO;
	}
	
	return YES;
}

- (BOOL)skipCommitWithHash:(NSString *)sha error:(NSError **)error {
	git_oid oid;
	BOOL success = [sha git_getOid:&oid error:error];
	if(!success) return NO;
	
	int gitError = git_revwalk_hide(self.walk, &oid);
	if(gitError < GIT_OK) {
		if (error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to hide sha on rev walker."];
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
	return [self nextObjectWithError:NULL];
}

- (id)nextObjectWithError:(NSError **)error {
	git_oid oid;
	int gitError = git_revwalk_next(&oid, self.walk);
	if(gitError == GIT_ITEROVER)
		return nil;
	
	// ignore error if we can't lookup object and just return nil
	return [self.repository lookupObjectBySha:[NSString git_stringWithOid:&oid] objectType:GTObjectTypeCommit error:error];
}

- (NSArray *)allObjects {
	return [self allObjectsWithError:NULL];
}

- (NSArray *)allObjectsWithError:(NSError **)error {
    NSMutableArray *array = [NSMutableArray array];
    id object = nil;
    while ((object = [self nextObjectWithError:error]) != nil) {
        [array addObject:object];
    }
    return array;
}

- (NSUInteger)countFromSha:(NSString *)sha error:(NSError **)error {
	[self setOptions:GTEnumeratorOptionsNone];
	
	BOOL success = [self push:sha error:error];
	if(!success) return NSNotFound;
	
	git_oid oid;
	NSUInteger count = 0;
	while(git_revwalk_next(&oid, self.walk) == GIT_OK) {
		count++;
	}
	return count;
}

- (void)setRepository:(GTRepository *)r {
	if(r == repository) return;
	
	repository = r;
	
	if(self.repository == nil) {
		[self cleanup];
	} else {
		[self.repository addEnumerator:self];
	}
}

@end
