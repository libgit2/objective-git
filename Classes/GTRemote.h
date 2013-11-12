//
//  GTRemote.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

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

// The URL string for the remote.
@property (nonatomic, readonly, copy) NSString *URLString;

// The fetch refspecs for this remote.
//
// This array will contain NSStrings of the form
// `+refs/heads/*:refs/remotes/REMOTE/*`.
@property (nonatomic, readonly, copy) NSArray *fetchRefspecs;

// Updates the URL string for this remote.
//
// URLString - The URLString to update to. May not be nil.
// error     - If not NULL, this will be set to any error that occurs when
//             updating the URLString or saving the remote.
//
// Returns YES if the URLString was successfully updated, NO and an error
// if updating or saving the remote failed.
- (BOOL)updateURLString:(NSString *)URLString error:(NSError **)error;

// Adds a fetch refspec to this remote.
//
// fetchRefspec - The fetch refspec string to add. May not be nil.
// error        - If not NULL, this will be set to any error that occurs
//                when adding the refspec or saving the remote.
//
// Returns YES if there is the refspec is successfully added
// or a matching refspec is already present, NO and an error if
// adding the refspec or saving the remote failed.
- (BOOL)addFetchRefspec:(NSString *)fetchRefspec error:(NSError **)error;

@end
