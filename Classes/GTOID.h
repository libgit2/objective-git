//
//  GTOID.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "git2.h"

// Represents an object ID.
@interface GTOID : NSObject < NSCopying >

// The SHA pointed to by the OID.
@property (nonatomic, readonly, copy) NSString *SHA;

// Initializes the receiver with the given git_oid.
//
// git_oid - The underlying git_oid. Cannot be NULL.
//
// Returns the initialized receiver.
- (id)initWithGitOid:(const git_oid *)git_oid;

// Initializes the receiver by converting the given SHA to an OID.
//
// SHA - The to convert to an OID. Cannot be nil.
//
// Returns the initialized receiver.
- (id)initWithSHA:(NSString *)SHA;

// Initializes the receiver by converting the given SHA C STring to an OID.
//
// string - The C string to convert. Cannot be NULL.
//
// Returns the initialized receiver.
- initWithSHACString: (const char *)string;

+ (instancetype)oidWithGitOid: (const git_oid *)git_oid;
+ (instancetype)oidWithSHA: (NSString *)SHA;
+ (instancetype)oidWithSHACString: (const char *)SHA;

// Returns the underlying git_oid struct.
- (const git_oid *)git_oid __attribute__((objc_returns_inner_pointer));

@end
