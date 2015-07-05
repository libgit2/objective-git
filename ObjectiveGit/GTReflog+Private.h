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

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver with a reference. Designated initializer.
///
/// reference - The reference whose reflog is being represented. Cannot be nil.
///
/// Returns the initialized object.
- (nullable instancetype)initWithReference:(GTReference *)reference NS_DESIGNATED_INITIALIZER;

@end
