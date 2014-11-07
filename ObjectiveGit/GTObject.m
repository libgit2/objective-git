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
#import "GTOID.h"

@interface GTObject ()
@property (nonatomic, readonly, assign) git_object *git_object;
@end

@implementation GTObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> type: %@, shortSha: %@, sha: %@", NSStringFromClass([self class]), self, self.type, self.shortSHA, self.SHA];
}

- (void)dealloc {
	if (_git_object != NULL) {
		git_object_free(_git_object);
		_git_object = NULL;
	}
}

- (NSUInteger)hash {
	return [self.SHA hash];
}

- (BOOL)isEqual:(id)otherObject {
	if(![otherObject isKindOfClass:[GTObject class]]) return NO;
	
	return 0 == git_oid_cmp(git_object_id(self.git_object), git_object_id(((GTObject *)otherObject).git_object)) ? YES : NO;
}


#pragma mark API 

- (id)initWithObj:(git_object *)object inRepository:(GTRepository *)repo {
	NSParameterAssert(object != NULL);
	NSParameterAssert(repo != nil);
	git_repository *object_repo __attribute__((unused)) = git_object_owner(object);
	NSAssert(object_repo == repo.git_repository, @"object %p doesn't belong to repo %@", object, repo);

	Class objectClass = nil;
	git_otype t = git_object_type(object);
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
			break;
	}

	if (!objectClass) {
		NSLog(@"Unknown git_otype %s (%d)", git_object_type2string(t), (int)t);
		return nil;
	}
	
	if (self.class != objectClass) {
		return [[objectClass alloc] initWithObj:object inRepository:repo];
	}
	
	self = [super init];
	if (!self) return nil;
	
	_repository = repo;
	_git_object = object;
	
	return self;
}

+ (id)objectWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo {
	return [[self alloc] initWithObj:theObject inRepository:theRepo];
}

- (NSString *)type {
	return [NSString stringWithUTF8String:git_object_type2string(git_object_type(self.git_object))];
}

- (GTOID *)OID {
	return [GTOID oidWithGitOid:git_object_id(self.git_object)];
}

- (NSString *)SHA {
	return self.OID.SHA;
}

- (NSString *)shortSHA {
	return [self.SHA git_shortUniqueShaString];
}

- (GTOdbObject *)odbObjectWithError:(NSError **)error {
	GTObjectDatabase *database = [self.repository objectDatabaseWithError:error];
	if (database == nil) return nil;

	return [database objectWithOID:self.OID error:error];
}

- (id)objectByPeelingToType:(GTObjectType)type error:(NSError **)error {
	git_object *peeled = NULL;
	int gitError = git_object_peel(&peeled, self.git_object, (git_otype)type);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Cannot peel object"];
		return nil;
	}

	return [GTObject objectWithObj:peeled inRepository:self.repository];
}

@end
