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

@end
