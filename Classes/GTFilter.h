//
//  GTFilter.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 2/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2.h"
#import "git2/sys/filter.h"

@class GTRepository;
@class GTFilterSource;

/// The error domain for errors originating from GTFilter.
extern NSString * const GTFilterErrorDomain;

/// A filter with that name has already been registered.
extern const NSInteger GTFilterErrorNameAlreadyRegistered;

/// Git filter abstraction.
///
/// **Note**: GTFilter is *not* thread safe.
@interface GTFilter : NSObject

/// Look up a filter based on its name.
///
/// Note that this will only find filters registered through
/// -registerWithPriority:error:.
///
/// Returns the filter, or nil if none was found.
+ (GTFilter *)lookUpFilterWithName:(NSString *)name;

/// Initializes the receiver with the given name and attributes and callback
/// blocks.
///
/// name       - The name of the filter. Cannot be nil.
/// attributes - The attributes to match against. See libgit2's documentation
///              for more details.
///
/// See the libgit2 description for the details on the various blocks.
///
/// Returns the initialized object.
- (id)initWithName:(NSString *)name attributes:(NSString *)attributes initializeBlock:(void (^)(void))initializeBlock shutdownBlock:(void (^)(void))shutdownBlock checkBlock:(BOOL (^)(void **payload, GTFilterSource *source, const char **attr_values))checkBlock applyBlock:(BOOL (^)(void **payload, NSData *from, NSData **to, GTFilterSource *source))applyBlock cleanupBlock:(void (^)(void *payload))cleanupBlock;

/// Registers the filter with the given priority.
///
/// priority - The priority for the filter. 0 is the standard for 3rd party
///            filters.
/// error    - The error if one occurred.
///
/// Returns whether the registration was successful.
- (BOOL)registerWithPriority:(int)priority error:(NSError **)error;

/// Unregisters the filter.
///
/// error - The error if one occurred.
///
/// Returns whether the unregistration was successful.
- (BOOL)unregister:(NSError **)error;

@end
