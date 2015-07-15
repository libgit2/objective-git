//
//  GTFilterSource.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 2/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/sys/filter.h"

@class GTOID;
@class GTRepository;

/// The potential filter modes.
///
/// GTFilterSourceModeSmudge - Performed when the source is going into the work
///                            tree.
/// GTFilterSourceModeClean  - Performed when the source is going into the ODB.
typedef NS_ENUM(NSInteger, GTFilterSourceMode) {
	GTFilterSourceModeSmudge = GIT_FILTER_SMUDGE,
	GTFilterSourceModeClean = GIT_FILTER_CLEAN,
};

NS_ASSUME_NONNULL_BEGIN

/// A source item for a filter.
@interface GTFilterSource : NSObject

/// The URL for the repository in which the item resides.
@property (nonatomic, readonly, strong) NSURL *repositoryURL;

/// The path of the file from which the source data is coming.
@property (nonatomic, readonly, copy) NSString *path;

/// The OID of the source. Will be nil if the source doesn't exist in the object
/// database.
@property (nonatomic, readonly, strong, nullable) GTOID *OID;

/// The filter mode.
@property (nonatomic, readonly, assign) GTFilterSourceMode mode;

- (instancetype)init NS_UNAVAILABLE;

/// Intializes the receiver with the given filter source. Designated initializer.
///
/// source - The filter source. Cannot be NULL.
///
/// Returns the initialized object.
- (nullable instancetype)initWithGitFilterSource:(const git_filter_source *)source NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
