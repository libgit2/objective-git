//
//  GTBlob.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/25/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>
#import "GTObject.h"

@interface GTBlob : GTObject {

}

@property (nonatomic, assign, readonly) NSInteger size;
@property (nonatomic, copy) NSString *content;

- (id)initInRepo:(GTRepository *)theRepo error:(NSError **)error;

@end
