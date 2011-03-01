//
//  GTCommit.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>
#import "GTObject.h"

@class GTSignature;
@class GTTree;

@interface GTCommit : GTObject {}

@property (nonatomic, assign, readonly) git_commit *commit;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy, readonly) NSString *messageShort;
@property (nonatomic, retain, readonly) NSDate *time;
@property (nonatomic, retain) GTSignature *author;
@property (nonatomic, retain) GTSignature *commiter;
@property (nonatomic, retain) GTTree *tree;
@property (nonatomic, retain, readonly) NSArray *parents;

- (id)initInRepo:(GTRepository *)theRepo error:(NSError **)error;

@end
