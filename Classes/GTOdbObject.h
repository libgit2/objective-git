//
//  GTOdbObject.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/23/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//


#import "GTObject.h"


@interface GTOdbObject : NSObject

// The repository in which the object resides.
@property (nonatomic, readonly, strong) GTRepository *repository;

@property (nonatomic, assign, readonly) git_odb_object *git_odb_object;

// Initializes the object with the underlying libgit2 object and repository.
//
// object     - The underlying libgit2 object. Cannot be NULL.
// repository - The repository in which the object resides. Cannot be nil.
//
// Returns the initialized object.
- (id)initWithOdbObj:(git_odb_object *)object repository:(GTRepository *)repository;

- (NSString *)shaHash;
- (GTObjectType)type;
- (size_t)length;
- (NSData *)data;
	
@end
