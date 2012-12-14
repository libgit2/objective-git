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
#import "GTTree.h"
#import "GTBlob.h"
#import "GTTag.h"

@interface GTObject ()
@property (nonatomic, assign) git_object *git_object;
@end


@implementation GTObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> type: %@, shortSha: %@, sha: %@", NSStringFromClass([self class]), self, self.type, self.shortSha, self.sha];
}

- (void)dealloc {
	self.repository = nil;
	git_object_free(self.git_object);
}

- (NSUInteger)hash {
	return [self.sha hash];
}

- (BOOL)isEqual:(id)otherObject {
	if(![otherObject isKindOfClass:[GTObject class]]) return NO;
	
	return 0 == git_oid_cmp(git_object_id(self.git_object), git_object_id(((GTObject *)otherObject).git_object)) ? YES : NO;
}


#pragma mark API 

@synthesize git_object;
@synthesize repository;

- (id)initWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo {
	if((self = [super init])) {
		self.repository = theRepo;
		self.git_object = theObject;
	}
	return self;
}

+ (id)objectWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo {	
	Class objectClass = nil;
	git_otype t = git_object_type(theObject);
	switch (t) {
		case GIT_OBJ_COMMIT:
			objectClass = [GTCommit class];
			break;
		case GIT_OBJ_TREE:
			objectClass = [GTTree class];
			break;
		case GIT_OBJ_BLOB:
			objectClass = [GTBlob class];
			break;
		case GIT_OBJ_TAG:
			objectClass = [GTTag class];
			break;
		default:
			objectClass = [GTObject class];
			break;
	}
	
    return [[objectClass alloc] initWithObj:theObject inRepository:theRepo];
}

+ (id)objectWithRevisionString:(NSString *)revisionString repository:(GTRepository *)repository {
	NSParameterAssert(revisionString != nil);
	NSParameterAssert(repository != nil);

	git_object *object = NULL;
	git_revparse_single(&object, repository.git_repository, revisionString.UTF8String);
	if (object == NULL) return nil;

	return [self objectWithObj:object inRepository:repository];
}

- (NSString *)type {
	return [NSString stringWithUTF8String:git_object_type2string(git_object_type(self.git_object))];
}

- (NSString *)sha {
	return [NSString git_stringWithOid:git_object_id(self.git_object)];
}

- (NSString *)shortSha {
	return [self.sha git_shortUniqueShaString];
}

- (GTOdbObject *)odbObjectWithError:(NSError **)error {
    return [self.repository.objectDatabase objectWithOid:git_object_id(self.git_object) error:error];
}

@end
