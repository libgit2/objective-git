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
#import "GTObjectDatabase.h"
#import "NSError+Git.h"
#import "GTRepository.h"
#import "NSString+Git.h"


static NSString * const GTCommitClassName = @"GTCommit";
static NSString * const GTTreeClassName = @"GTTree";
static NSString * const GTBlobClassName = @"GTBlob";
static NSString * const GTObjectClassName = @"GTObject";
static NSString * const GTTagClassName = @"GTTag";

@implementation GTObject

- (void)dealloc {
	
	self.repository = nil;
	[super dealloc];
}

- (NSUInteger)hash {
	
	return [self.sha hash];
}

- (BOOL)isEqual:(id)otherObject {
	
	if(![otherObject isKindOfClass:[GTObject class]]) return NO;
	
	return 0 == git_oid_cmp(git_object_id(self.obj), git_object_id(((GTObject *)otherObject).obj)) ? YES : NO;
}

#pragma mark -
#pragma mark API 

@synthesize obj;
@synthesize type;
@synthesize sha;
@synthesize repository;

- (id)initWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo {
	
	if((self = [super init])) {
		self.repository = theRepo;
		obj = theObject;
	}
	return self;
}
+ (id)objectWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo {
	
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
	
    return [[[NSClassFromString(klass) alloc] initWithObj:theObject inRepository:theRepo] autorelease];
}

- (NSString *)type {
	
	return [NSString stringWithUTF8String:git_object_type2string(git_object_type(self.obj))];
}

- (NSString *)sha {
	
	return [NSString git_stringWithOid:git_object_id(self.obj)];
}

- (NSString *)shortSha {
	
	return [self.sha git_shortUniqueShaString];
}

- (GTOdbObject *)odbObjectWithError:(NSError **)error {
	
    return [self.repository.objectDatabase objectWithOid:git_object_id(self.obj) error:error];
}

@end
