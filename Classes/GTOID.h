//
//  GTOID.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "git2.h"

// Represents an object ID.
@interface GTOID : NSObject

// The underlying git_oid struct.
@property (nonatomic, readonly, assign) git_oid *git_oid;

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

@end
