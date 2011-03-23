//
//  GTOdbObject.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/23/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import <git2.h>


@interface GTOdbObject : NSObject {}

@property (nonatomic, assign, readonly) git_odb_object *odbObject;

- (id)initWithObject:(git_odb_object *)object;
+ (id)objectWithObject:(git_odb_object *)object;

- (NSString *)hash;
- (NSString *)type;
- (NSUInteger)length;
- (NSData *)data;
- (NSString *)dataAsUTF8String;
	
@end
