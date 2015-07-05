//
//  GTOID.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/oid.h"
#import "GTObject.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents an object ID.
@interface GTOID : NSObject <NSCopying>

/// The SHA pointed to by the OID.
@property (nonatomic, readonly, copy) NSString *SHA;

/// Is the OID all zero? This usually indicates that the object has not been
/// inserted into the ODB yet.
@property (nonatomic, readonly, assign, getter = isZero) BOOL zero;

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver with the given git_oid. Designated initializer.
///
/// git_oid - The underlying git_oid. Cannot be NULL.
///
/// Returns the initialized receiver.
- (instancetype)initWithGitOid:(const git_oid *)git_oid NS_DESIGNATED_INITIALIZER;

/// Initializes the receiver by converting the given SHA to an OID.
///
/// SHA - The to convert to an OID. Cannot be nil.
///
/// Returns the initialized receiver.
- (nullable instancetype)initWithSHA:(NSString *)SHA;

/// Initializes the receiver by converting the given SHA to an OID
/// optionally returning a NSError instance on failure.
///
/// SHA   - The to convert to an OID. Cannot be nil.
/// error - Will be filled with an error object in if the SHA cannot be parsed
///
/// Returns the initialized receiver or nil if an error occured.
- (nullable instancetype)initWithSHA:(NSString *)SHA error:(NSError **)error;

/// Initializes the receiver by converting the given SHA C string to an OID.
///
/// string - The C string to convert. Cannot be NULL.
///
/// Returns the initialized receiver.
- (nullable instancetype)initWithSHACString:(const char *)string;

/// Initializes the receiver by converting the given SHA C string to an OID
/// optionally returning a NSError instance on failure.
///
/// string - The C string to convert. Cannot be NULL.
/// error  - Will be filled with an error object in if the SHA cannot be parsed
///
/// Returns the initialized receiver.
- (nullable instancetype)initWithSHACString:(const char *)string error:(NSError **)error NS_DESIGNATED_INITIALIZER;

/// Creates a new instance with the given git_oid using initWithGitOid:
+ (instancetype)oidWithGitOid:(const git_oid *)git_oid;

/// Creates a new instance from the given SHA string using initWithSHAString:
+ (nullable instancetype)oidWithSHA:(NSString *)SHA;

/// Creates a new instance from the given SHA C string using initWithSHACString:
+ (nullable instancetype)oidWithSHACString:(const char *)SHA;

/// Returns the underlying git_oid struct.
- (const git_oid *)git_oid __attribute__((objc_returns_inner_pointer));

@end

@interface GTOID (GTObjectDatabase)

/// Calculates an OID by hashing the passed data and object type.
///
/// data - The data to hash. Cannot be nil.
/// type - The type of the git object.
///
/// Returns a new OID, or nil if an error occurred.
+ (nullable instancetype)OIDByHashingData:(NSData *)data type:(GTObjectType)type error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
