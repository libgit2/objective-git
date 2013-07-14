//
//  GTPartialOID.h
//  ObjectiveGitFramework
//
//  Created by Sven Weidauer on 14.07.13.
//  Copyright (c) 2013 Sven Weidauer. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface GTPartialOID : GTOID

// Length (in hex characters) of this partial object ID.
@property (nonatomic) size_t length;

// Parses a partial object ID from a C string
//
// string - The string to parse. Needs to be at least length characters long.
// length - Length of the string. Needs to be greater than zero and smaller
//          or equal to GIT_OID_HEXSZ.
// error  - Will be filled with a NSError instance on failuer. May be NULL.
//
// Returns the initialized GTPartialOID or nil on error.
- (id)initWithSHACString:(const char *)string length: (size_t)length error:(NSError **)error;

// Initializes a partial object ID
//
// git_oid - The git_oid with the data
// length  - Length (in hex characters) of the object ID. Needs to be
//           greater than zero and smaller or equal to GIT_OID_HEXSZ
//
// Returns the initialized GTPartialOID
- (id)initWithGitOid:(const git_oid *)git_oid length:(size_t)length;

@end
