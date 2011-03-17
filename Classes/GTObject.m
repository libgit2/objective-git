//
//  GTObject.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
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
#import "GTCommit.h"
#import "GTRawObject.h"
#import "GTLib.h"
#import "NSError+Git.h"
#import "NSString+Git.h"
#import "GTRepository.h"


static NSString * const GTCommitClassName = @"GTCommit";
static NSString * const GTTreeClassName = @"GTTree";
static NSString * const GTBlobClassName = @"GTBlob";
static NSString * const GTObjectClassName = @"GTObject";
static NSString * const GTTagClassName = @"GTTag";

@implementation GTObject

- (void)dealloc {
	
	self.repo = nil;
	[super dealloc];
}

- (NSUInteger)hash {
	
	return [self.sha hash];
}

- (BOOL)isEqual:(id)otherObject {
	
	if(![otherObject isKindOfClass:[GTObject class]]) return NO;
	
	return 0 == git_oid_cmp(git_object_id(self.object), git_object_id(((GTObject *)otherObject).object)) ? YES : NO;
}

#pragma mark -
#pragma mark API 

@synthesize object;
@synthesize type;
@synthesize sha;
@synthesize repo;

- (id)initInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject {
	
	if((self = [super init])) {
		self.repo = theRepo;
		self.object = theObject;
	}
	return self;
}
+ (id)objectInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject {
	
	NSString *klass;
	git_otype t = git_object_type(theObject);
	switch (t) {
		case GIT_OBJ_COMMIT:
			klass = GTCommitClassName;
			break;
		case GIT_OBJ_TREE:
			klass = GTTreeClassName;
			break;
		case GIT_OBJ_BLOB:
			klass = GTBlobClassName;
			break;
		case GIT_OBJ_TAG:
			klass = GTTagClassName;
			break;
		default:
			klass = GTObjectClassName;
			break;
	}
	
	return [[[NSClassFromString(klass) alloc] initInRepo:theRepo withObject:theObject] autorelease];
}

+ (git_object *)getNewObjectInRepo:(git_repository *)r type:(GTObjectType)theType error:(NSError **)error {
	
	git_object *obj;
	int gitError = git_object_new(&obj, r, theType);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForNewObject:gitError];
		return nil;
	}
	return obj;
}

+ (git_object *)getNewObjectInRepo:(git_repository *)r sha:(NSString *)sha type:(GTObjectType)theType error:(NSError **)error {
	
	git_object *obj = NULL;
	git_oid oid;
	
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:sha]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
	
	gitError = git_object_lookup(&obj, r, &oid, theType);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForLookupObject:gitError];
		return nil;
	}
	NSAssert(obj, @"Failed to lookup git_object from repo");
	return obj;
}

- (NSString *)type {
	
	return [NSString stringForUTF8String:git_object_type2string(git_object_type(self.object))];
}

- (NSString *)sha {
	
	return [GTLib convertOidToSha:git_object_id(self.object)];
}

- (NSString *)shortSha {
	
	return [GTLib shortUniqueShaFromSha:self.sha];
}

- (NSString *)writeAndReturnError:(NSError **)error {
	
	int gitError = git_object_write(self.object);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForWriteObject:gitError];
		return nil;
	}
	return self.sha;
}

- (GTRawObject *)readRawAndReturnError:(NSError **)error {
	
	return [self.repo rawRead:git_object_id(self.object) error:error];
}

@end
