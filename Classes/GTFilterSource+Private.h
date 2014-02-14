//
//  GTFilterSource+Private.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 2/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFilterSource.h"

@interface GTFilterSource ()

/// Intializes the receiver with the given filter source.
///
/// source - The filter source. Cannot be NULL.
///
/// Returns the initialized object.
- (id)initWithGitFilterSource:(const git_filter_source *)source;

@end
