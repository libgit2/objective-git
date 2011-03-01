//
//  GTSignature.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>
#import "GTObject.h"

@interface GTSignature : NSObject {}

@property (nonatomic, assign) git_signature *signature;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *email;
@property (nonatomic, retain) NSDate *time;

+ (id)signatureWithSignature:(git_signature *)theSignature;
- (id)initWithSignature:(git_signature *)theSignature;
+ (id)signatureWithName:(NSString *)theName email:(NSString *)theEmail time:(NSDate *)theTime;
- (id)initWithName:(NSString *)theName email:(NSString *)theEmail time:(NSDate *)theTime;

@end
