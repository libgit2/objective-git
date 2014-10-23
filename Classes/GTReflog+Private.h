//
//  GTReflog+Private.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTReflog.h"

@class GTReference;

@interface GTReflog ()

/// Initializes the receiver with a reference.
///
/// reference - The reference whose reflog is being represented. Cannot be nil.
///
/// Returns the initialized object.
- (id)initWithReference:(GTReference *)reference;

@end
