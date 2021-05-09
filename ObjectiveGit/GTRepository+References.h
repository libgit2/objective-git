//
//  GTRepository+References.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 6/4/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

NS_ASSUME_NONNULL_BEGIN

@class GTReference;

@interface GTRepository (References)

/// Look up a reference by name.
///
/// name  - The name of the reference to look up. Cannot be nil.
/// error - The error if one occurs. May be NULL.
///
/// Returns the reference or nil if look up failed.
- (GTReference * _Nullable)lookUpReferenceWithName:(NSString *)name error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
