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

@interface GTEnumerator ()

@property (nonatomic, assign, readonly) git_revwalk *walk;
@property (nonatomic, assign, readwrite) GTEnumeratorOptions options;

@end

@implementation GTEnumerator

#pragma mark Lifecycle

+ (id)enumeratorWithRepository:(GTRepository *)theRepo error:(NSError **)error {
	return [[self alloc] initWithRepository:theRepo error:error];
}

- (id)initWithRepository:(GTRepository *)repo error:(NSError **)error {
	NSParameterAssert(repo != nil);

	self = [super init];
	if (self == nil) return nil;

	_repository = repo;
	_options = GTEnumeratorOptionsNone;

	int gitError = git_revwalk_new(&_walk, self.repository.git_repository);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to initialize rev walker."];
		return nil;
	}

	return self;
}

- (void)dealloc {
	if (_walk != NULL) {
		git_revwalk_free(_walk);
		_walk = NULL;
	}
}

#pragma mark Pushing and Skipping

- (BOOL)pushSHA:(NSString *)sha error:(NSError **)error {
	NSParameterAssert(sha != nil);

	git_oid oid;
	BOOL success = [sha git_getOid:&oid error:error];
	if (!success) return NO;
	
	int gitError = git_revwalk_push(self.walk, &oid);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to push SHA onto rev walker."];
		return NO;
	}
	
	return YES;
}

- (BOOL)pushGlob:(NSString *)refGlob error:(NSError **)error {
	NSParameterAssert(refGlob != nil);

	int gitError = git_revwalk_push_glob(self.walk, refGlob.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to push glob onto rev walker."];
		return NO;
	}
	
	return YES;
}

- (BOOL)skipSHA:(NSString *)sha error:(NSError **)error {
	NSParameterAssert(sha != nil);

	git_oid oid;
	BOOL success = [sha git_getOid:&oid error:error];
	if (!success) return NO;
	
	int gitError = git_revwalk_hide(self.walk, &oid);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to hide SHA on rev walker."];
		return NO;
	}

	return YES;
}

- (BOOL)skipGlob:(NSString *)refGlob error:(NSError **)error {
	NSParameterAssert(refGlob != nil);

	int gitError = git_revwalk_hide_glob(self.walk, refGlob.UTF8String);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to push glob onto rev walker."];
		return NO;
	}
	
	return YES;
}

#pragma mark Resetting

- (void)resetWithOptions:(GTEnumeratorOptions)options {
	self.options = options;

	// This will also reset the walker.
	git_revwalk_sorting(self.walk, self.options);
}

#pragma mark Enumerating

- (GTCommit *)nextObjectWithError:(NSError **)error {
	git_oid oid;
	int gitError = git_revwalk_next(&oid, self.walk);
	if (gitError == GIT_ITEROVER) return nil;
	
	// Ignore error if we can't lookup object and just return nil.
	return (id)[self.repository lookupObjectBySha:[NSString git_stringWithOid:&oid] objectType:GTObjectTypeCommit error:error];
}

- (NSArray *)allObjectsWithError:(NSError **)error {
	NSMutableArray *array = [NSMutableArray array];

	GTCommit *object;
	do {
		NSError *localError = nil;
		object = [self nextObjectWithError:&localError];

		if (object != nil) {
			[array addObject:object];
		} else if (localError != nil) {
			if (error != NULL) *error = localError;
			return nil;
		}
	} while (object != nil);

	return array;
}

- (NSUInteger)countRemainingObjectsWithError:(NSError **)error {
	git_oid oid;

	int gitError;
	NSUInteger count = 0;

	while ((gitError = git_revwalk_next(&oid, self.walk)) == GIT_OK) {
		count++;
	}

	if (gitError == GIT_ITEROVER) {
		return count;
	} else {
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to get next SHA with rev walker."];
		return NSNotFound;
	}
}

#pragma mark NSEnumerator

- (NSArray *)allObjects {
	return [self allObjectsWithError:NULL];
}

- (id)nextObject {
	return [self nextObjectWithError:NULL];
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> repository: %@", self.class, self, self.repository];
}

@end
