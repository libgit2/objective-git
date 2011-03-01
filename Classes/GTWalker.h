//
//  GTWalker.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/21/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>
#import "GTRepository.h"
#import "GTObject.h"

@class GTCommit;

@interface GTWalker : NSObject {}

@property (nonatomic, retain) GTRepository *repo;

- (id)initWithRepository:(GTRepository *)theRepo error:(NSError **)error;
- (void)push:(NSString *)sha error:(NSError **)error;
- (void)hide:(NSString *)sha error:(NSError **)error;
- (void)reset;
- (void)sorting:(unsigned int)sortMode;
- (GTCommit *)next;

@end
