//
//  GTRepository+Attributes.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 7/25/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

NS_ASSUME_NONNULL_BEGIN

@interface GTRepository (Attributes)

/// Look up the value for the attribute of the given name for the given path.
///
/// name - The name of the attribute to look up. Cannot be nil.
/// path - The path to use for the lookup. Cannot be nil.
///
/// Returns the value of the attribute or nil.
- (nullable NSString *)attributeWithName:(NSString *)name path:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
