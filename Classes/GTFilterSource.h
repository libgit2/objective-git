//
//  GTFilterSource.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 2/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2.h"
#import "git2/sys/filter.h"

@class GTOID;
@class GTRepository;

/// The potential filter modes.
///
/// GTFilterSourceModeSmudge - Performed when the source is going into the work
///                            tree.
/// GTFilterSourceModeClean  - Performed when the source is going into the ODB.
typedef enum {
	GTFilterSourceModeSmudge = GIT_FILTER_SMUDGE,
	GTFilterSourceModeClean = GIT_FILTER_CLEAN,
} GTFilterSourceMode;

/// A source item for a filter.
@interface GTFilterSource : NSObject

/// The URL for the repository in which the item resides.
@property (nonatomic, readonly, strong) NSURL *repositoryURL;

/// The path of the file from which the source data is coming.
@property (nonatomic, readonly, copy) NSString *path;

/// The OID of the source. Will be nil if the source doesn't exist in the object
/// database.
@property (nonatomic, readonly, strong) GTOID *OID;

/// The filter mode.
@property (nonatomic, readonly, assign) GTFilterSourceMode mode;

/// Intializes the receiver with the given filter source.
///
/// source - The filter source. Cannot be NULL.
///
/// Returns the initialized object.
- (id)initWithGitFilterSource:(const git_filter_source *)source;

@end
