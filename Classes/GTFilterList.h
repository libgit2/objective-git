//
//  GTFilterList.h
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2014-02-20.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2.h"

@class GTBlob;
@class GTRepository;

/// An opaque list of filters that apply to a given path.
@interface GTFilterList : NSObject

/// Initializes the receiver to wrap the given `git_filter_list`.
- (instancetype)initWithGitFilterList:(git_filter_list *)filterList;

/// Returns the underlying `git_filter_list`.
- (git_filter_list *)git_filter_list __attribute__((objc_returns_inner_pointer));

/// Attempts to apply the filter list to `data`.
///
/// data  - The data to filter. Must not be nil.
/// error - If not NULL, set to any error that occurs.
///
/// Returns the filtered data, or nil if an error occurs.
- (NSData *)applyToData:(NSData *)data error:(NSError **)error; 

/// Attempts to apply the filter list to a file in the given repository.
///
/// relativePath - A relative path to the file in `repository` that should be
///                filtered. Must not be nil.
/// repository   - The repository in which to apply the filter. Must not be nil.
/// error        - If not NULL, set to any error that occurs.
///
/// Returns the filtered data, or nil if an error occurs.
- (NSData *)applyToPath:(NSString *)relativePath inRepository:(GTRepository *)repository error:(NSError **)error;

/// Attempts to apply the filter list to a blob.
///
/// blob  - A blob of the data that should be filtered. Must not be nil.
/// error - If not NULL, set to any error that occurs.
///
/// Returns the filtered data, or nil if an error occurs.
- (NSData *)applyToBlob:(GTBlob *)blob error:(NSError **)error;

@end
