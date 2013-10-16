//
//  GTRemote.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

// A class representing a remote for a git repository.
//
// Analagous to `git_remote` in libgit2.
@interface GTRemote : NSObject

// Initializes a new GTRemote to represent an underlying `git_remote`.
//
// remote - The underlying `git_remote` object.
- (id)initWithGitRemote:(git_remote *)remote;

// The underlying `git_remote` object.
- (git_remote *)git_remote __attribute__((objc_returns_inner_pointer));

// The name of the remote.
@property (nonatomic, readonly, copy) NSString *name;

// The push and fetch URL for this remote.
@property (nonatomic, readonly, copy) NSString *URLString;

// The fetch refspecs for this remote.
// Example of a refspec is: @"+refs/heads/*:refs/remotes/%@/*".
//
// Returns an NSArray of NSStrings.
@property (nonatomic, readonly, copy) NSArray *fetchRefSpecs;

// Updates the URL string for this remote.
//
// Returns YES if the URLString was succesfully updated.
// Returns NO and an error if updating failed.
- (BOOL)updateURLString:(NSString *)URLString error:(NSError **)error;

// Adds a fetch refspec to this remote.
//
// Returns YES if there is the refspec is successflly added
// or a matching refspec is already present.
// Returns NO and an error if updating failed.
- (BOOL)addFetchRefSpec:(NSString *)fetchRefSpec error:(NSError **)error;

// Removes the first fetchRefSpec that matches.
//
// Returns YES if the matching refspec is found and removed, or if no matching
// refspec was found.
// Returns NO and error if a matching refspec was found but could
// not be removed.
- (BOOL)removeFetchRefSpec:(NSString *)fetchRefSpec error:(NSError **)error;

@end
