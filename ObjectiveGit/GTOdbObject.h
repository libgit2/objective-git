//
//  GTOdbObject.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/23/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import "GTObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface GTOdbObject : NSObject

/// The repository in which the object resides.
@property (nonatomic, readonly, strong) GTRepository *repository;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the object with the underlying libgit2 object and repository. Designated initializer.
///
/// object     - The underlying libgit2 object. Cannot be NULL.
/// repository - The repository in which the object resides. Cannot be nil.
///
/// Returns the initialized object.
- (nullable instancetype)initWithOdbObj:(git_odb_object *)object repository:(GTRepository *)repository NS_DESIGNATED_INITIALIZER;

/// The underlying `git_odb_object`.
- (git_odb_object *)git_odb_object __attribute__((objc_returns_inner_pointer));

- (nullable NSString *)shaHash;
- (GTObjectType)type;
- (size_t)length;
- (nullable NSData *)data;

/// The object ID of this object.
@property (nonatomic, readonly, nullable) GTOID *OID;
	
@end

NS_ASSUME_NONNULL_END
