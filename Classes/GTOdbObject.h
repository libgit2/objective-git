//
//  GTOdbObject.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/23/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//


#import "GTObject.h"


@interface GTOdbObject : NSObject {}

@property (nonatomic, assign, readonly) git_odb_object *git_odb_object;

- (id)initWithOdbObj:(git_odb_object *)object;
+ (id)objectWithOdbObj:(git_odb_object *)object;

- (NSString *)shaHash;
- (GTObjectType)type;
- (size_t)length;
- (NSData *)data;
	
@end
