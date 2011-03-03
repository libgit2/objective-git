//
//  GTBranch.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/3/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GHWalkable.h"

@class GTRepository;


@interface GTBranch : NSObject <GHWalkable> {}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, retain) GTRepository *repository;

- (id)initWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error;

@end
