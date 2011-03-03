//
//  GHWalkable.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/3/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class GTWalker;


@protocol GHWalkable

- (GTWalker *)walkerWithError:(NSError **)error;

@end
