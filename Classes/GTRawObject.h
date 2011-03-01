//
//  GTRawObject.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/24/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>

@interface GTRawObject : NSObject {}

@property (nonatomic, assign) git_otype type;
@property (nonatomic, copy) NSData *data;

+ (id)rawObjectWithType:(git_otype)theType data:(NSData *)theData;
+ (id)rawObjectWithType:(git_otype)theType string:(NSString *)string;
- (id)initWithType:(git_otype)theType data:(NSData *)theData;
- (id)initWithType:(git_otype)theType string:(NSString *)string;
- (NSString *)dataAsUTF8String;

@end
