//
//  GTMerge.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 26/10/2018.
//  Copyright © 2018 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/merge.h"

NS_ASSUME_NONNULL_BEGIN

/// Represents the result of a merge
@interface GTMergeResult : NSObject

/// Was the merge automerable ?
@property (readonly,getter=isAutomergeable) BOOL automergeable;

/// The path of the resulting merged file, nil in case of conflicts
@property (readonly) NSString * _Nullable path;

/// The resulting mode of the merged file
@property (readonly) unsigned int mode;

/// The contents of the resulting merged file
@property (readonly) NSData *data;

/// Initialize the merge result from a libgit2 struct.
/// Ownership of the memory will be transferred to the receiver.
- (instancetype)initWithGitMergeFileResult:(git_merge_file_result *)result;

- (instancetype)init NS_UNAVAILABLE;

@end

/// Represents inputs for a tentative merge
@interface GTMergeFile : NSObject

/// The file data
@property (readonly) NSData *data;

/// The file path. Can be nil to not merge paths.
@property (readonly) NSString * _Nullable path;

/// The file mode. Can be 0 to not merge modes.
@property (readonly) unsigned int mode;

/// Perform a merge between files
///
/// ancestorFile - The file to consider the ancestor
/// ourFile      - The file to consider as our version
/// theirFile    - The file to consider as the incoming version
/// options      - The options of the merge. Can be nil.
/// error        - A pointer to an error object. Can be NULL.
///
/// Returns the result of the merge, or nil if an error occurred.
+ (GTMergeResult * _Nullable)performMergeWithAncestor:(GTMergeFile *)ancestorFile ourFile:(GTMergeFile *)ourFile theirFile:(GTMergeFile *)theirFile options:(NSDictionary * _Nullable)options error:(NSError **)error;

+ (instancetype)fileWithString:(NSString *)string path:(NSString * _Nullable)path mode:(unsigned int)mode;

/// Initialize an input file for a merge
- (instancetype)initWithData:(NSData *)data path:(NSString * _Nullable)path mode:(unsigned int)mode NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/// Inner pointer to a libgit2-compatible git_merge_file_input struct.
- (git_merge_file_input *)git_merge_file_input __attribute__((objc_returns_inner_pointer));

@end

NS_ASSUME_NONNULL_END
