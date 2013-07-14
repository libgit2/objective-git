//
//  GTOID_Private.h
//  ObjectiveGitFramework
//
//  Created by Sven Weidauer on 14.07.13.
//  Copyright (c) 2013 Sven Weidauer. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@interface GTOID ()

// Looks up an object identified by this ID
//
// repo  - The repository to look up this object in
// type  - The object type to look for
// error - Will be filled with an error message on failure. May be NULL.
//
// Returns the looked-up object or nil on error.
- (GTObject *)lookupObjectInRepository:(GTRepository *)repo type:(GTObjectType)type error:(NSError **)error;

// Internal lookup method. Compare git_object_lookup and git_object_lookup_prefix
- (int)lookupObject:(git_object **)object repository:(git_repository *)repo type:(git_otype)type;

// Internal read method. Compare git_odb_read/git_odb_read_prefix
- (int)readObject:(git_odb_object **)object database:(git_odb *)db;

@end
