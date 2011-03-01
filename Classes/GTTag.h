//
//  GTTag.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>
#import "GTObject.h"

@class GTSignature;

@interface GTTag : GTObject {

}

@property (nonatomic, assign) git_tag *tag;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) GTObject *target;
@property (nonatomic, copy) NSString *targetType;
@property (nonatomic, retain) GTSignature *tagger;

@end
