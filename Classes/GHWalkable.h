//
//  GHWalkable.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/3/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GTWalker.h"


@protocol GHWalkable

- (GTWalker *)walkerWithOptions:(GTWalkerOptions)options error:(NSError **)error;

@end
