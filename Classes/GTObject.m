//
//  GTObject.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTObject.h"
#import "GTCommit.h"
#import "GTRawObject.h"
#import "NSError+Git.h"
#import "NSString+Git.h"

static NSString * const GTCommitClassName = @"GTCommit";
static NSString * const GTTreeClassName = @"GTTree";
static NSString * const GTBlobClassName = @"GTBlob";
static NSString * const GTObjectClassName = @"GTObject";
static NSString * const GTTagClassName = @"GTTag";

@implementation GTObject

@synthesize type;
@synthesize sha;

@synthesize object;
@synthesize repo;

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

- (id)initInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject {
	
	if(self = [super init]){
		self.repo = theRepo;
		self.object = theObject;
	}
	return self;
}

+ (git_object *)getNewObjectInRepo:(git_repository *)r type:(git_otype)theType error:(NSError **)error {
	
	git_object *obj;
	int gitError = git_repository_newobject(&obj, r, theType);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForNewObject:gitError];
		return nil;
	}
	return obj;
}

+ (git_object *)getNewObjectInRepo:(git_repository *)r sha:(NSString *)sha type:(git_otype)theType error:(NSError **)error {
	
	git_object *obj = NULL;
	git_oid oid;
	git_oid_mkstr(&oid, [NSString utf8StringForString:sha]);
	int gitError = git_repository_lookup(&obj, r, &oid, theType);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForLookupSha:gitError];
		return nil;
	}
	NSAssert(obj, @"Failed to lookup git_object from repo");
	return obj;
}

- (NSString *)type {
	
	return [NSString stringForUTF8String:git_object_type2string(git_object_type(self.object))];
}

- (NSString *)sha {
	
	char hex[41];
	git_oid_fmt(hex, git_object_id(self.object));
	hex[40] = 0;
	return [NSString stringForUTF8String:hex];
}

- (NSString *)writeAndReturnError:(NSError **)error {
	
	int gitError = git_object_write(self.object);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForWriteObject:gitError];
		return nil;
	}
	return self.sha;
}

- (GTRawObject *)readRawAndReturnError:(NSError **)error {
	
	return [self.repo rawRead:git_object_id(self.object) error:error];
}

- (NSUInteger)hash {
	return [self.sha hash];
}

- (BOOL)isEqual:(id)otherObject {
	if(![otherObject isKindOfClass:[GTObject class]]) return NO;
	
	return 0 == git_oid_cmp(git_object_id(self.object), git_object_id(((GTObject *)otherObject).object)) ? YES : NO;
}

// Do NOT call git_object_free()
// The object is owned by the repo and will be 
// garbage collected when the repo is freed
/*- (void)finalize {
	
	git_object_free(object);
	[super finalize];
}*/

@end
