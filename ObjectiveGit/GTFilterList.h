//
//  GTFilterList.h
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2014-02-20.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/filter.h"

@class GTBlob;
@class GTRepository;

/// The options for loading a filter list. See libgit2 for more information.
typedef NS_OPTIONS(NSInteger, GTFilterListOptions) {
	GTFilterListOptionsDefault = GIT_FILTER_DEFAULT,
	GTFilterListOptionsAllowUnsafe = GIT_FILTER_ALLOW_UNSAFE,
};

NS_ASSUME_NONNULL_BEGIN

/// An opaque list of filters that apply to a given path.
@interface GTFilterList : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Initializes the receiver to wrap the given `git_filter_list`. Designated initializer.
///
/// filterList - The filter list to wrap and take ownership of. This filter list
///              will be automatically disposed when the receiver deallocates.
///              Must not be NULL.
///
/// Returns an initialized filter list, or nil if an error occurred.
- (nullable instancetype)initWithGitFilterList:(git_filter_list *)filterList NS_DESIGNATED_INITIALIZER;

/// Returns the underlying `git_filter_list`.
- (git_filter_list *)git_filter_list __attribute__((objc_returns_inner_pointer));

/// Attempts to apply the filter list to a data buffer.
///
/// inputData - The data to filter. Must not be nil.
/// error     - If not NULL, set to any error that occurs.
///
/// Returns the filtered data, or nil if an error occurs.
- (nullable NSData *)applyToData:(NSData *)inputData error:(NSError **)error;

/// Attempts to apply the filter list to a file in the given repository.
///
/// relativePath - A relative path to the file in `repository` that should be
///                filtered. Must not be nil.
/// repository   - The repository in which to apply the filter. Must not be nil.
/// error        - If not NULL, set to any error that occurs.
///
/// Returns the filtered data, or nil if an error occurs.
- (nullable NSData *)applyToPath:(NSString *)relativePath inRepository:(GTRepository *)repository error:(NSError **)error;

/// Attempts to apply the filter list to a blob.
///
/// blob  - A blob of the data that should be filtered. Must not be nil.
/// error - If not NULL, set to any error that occurs.
///
/// Returns the filtered data, or nil if an error occurs.
- (nullable NSData *)applyToBlob:(GTBlob *)blob error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
