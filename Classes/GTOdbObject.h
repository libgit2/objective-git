//
//  GTOdbObject.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/23/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//


#import "GTObject.h"

@interface GTOdbObject : NSObject {}

@property (nonatomic, assign, readonly) git_odb_object *odbObject;

- (id)initWithOdbObj:(git_odb_object *)object;
+ (id)objectWithOdbObj:(git_odb_object *)object;

- (NSString *)shaHash;
- (GTObjectType)type;
- (NSUInteger)length;
- (NSData *)data;
- (NSString *)dataAsUTF8String;
	
@end
