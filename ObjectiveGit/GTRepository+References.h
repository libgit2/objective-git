//
//  GTRepository+References.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 6/4/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import "GTrepository.h"

NS_ASSUME_NONNULL_BEGIN

@class GTReference;

@interface GTRepository (References)

/// Look up a reference by name.
///
/// name  - The name of the reference to look up. Cannot be nil.
/// error - The error if one occurs. May be NULL.
///
/// Returns the reference or nil if look up failed.
- (nullable GTReference *)lookUpReferenceWithName:(NSString *)name error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
