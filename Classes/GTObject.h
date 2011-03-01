//
//  GTObject.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>
#import "GTRepository.h"

/*typedef enum {
	Commit = 1,
	Tree = 2,
	Blob = 3,
	Tag = 4
} GTObjectType;*/

@interface GTObject : NSObject {}

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *sha;
@property (nonatomic, assign) git_object *object;
@property (nonatomic, retain) GTRepository *repo;

+ (git_object *)getNewObjectInRepo:(git_repository *)r type:(git_otype)theType error:(NSError **)error;
+ (git_object *)getNewObjectInRepo:(git_repository *)r sha:(NSString *)sha type:(git_otype)theType error:(NSError **)error;

+ (id)objectInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject; 
- (id)initInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject;
- (NSString *)writeAndReturnError:(NSError **)error;
- (GTRawObject *)readRawAndReturnError:(NSError **)error;

@end

