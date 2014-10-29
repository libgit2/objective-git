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
/// **Note**: GTFilter is *not* thread safe. Registration and unregistration
/// should be done before any repository actions are taken.
@interface GTFilter : NSObject

/// The initialize block. This will be called once before the filter is used for
/// the first time.
@property (nonatomic, copy) void (^initializeBlock)(void);

/// The shutdown block. This will be called when libgit2 is shutting down.
@property (nonatomic, copy) void (^shutdownBlock)(void);

/// The check block. Determines whether the `applyBlock` should be run for given
/// source.
@property (nonatomic, copy) BOOL (^checkBlock)(void **payload, GTFilterSource *source, const char **attr_values);

/// The cleanup block. Called after the `applyBlock` to given the filter a
/// chance to clean up the `payload`.
@property (nonatomic, copy) void (^cleanupBlock)(void *payload);

/// Initializes the object with the given name and attributes.
///
/// name       - The name for the filter. Cannot be nil.
/// attributes - The attributes to which this filter applies. May be nil.
/// applyBlock - The block to use to apply the filter. Cannot be nil.
///
/// Returns the initialized object.
- (id)initWithName:(NSString *)name attributes:(NSString *)attributes applyBlock:(NSData * (^)(void **payload, NSData *from, GTFilterSource *source, BOOL *applied))applyBlock;

/// Look up a filter based on its name.
///
/// Note that this will only find filters registered through
/// -registerWithName:priority:error:.
///
/// Returns the filter, or nil if none was found.
+ (GTFilter *)filterForName:(NSString *)name;

/// Registers the filter with the given priority.
///
/// priority - The priority for the filter. 0 is the standard for 3rd party
///            filters. Higher numbers are given more priority and therefore
///            called before lower priority filters. A negative number is fine.
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
