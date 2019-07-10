//
//  GTAnnotatedCommit.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 18/12/2016.
//  Copyright © 2016 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <git2/annotated_commit.h>

@class GTReference;
@class GTRepository;
@class GTOID;

NS_ASSUME_NONNULL_BEGIN

@interface GTAnnotatedCommit : NSObject

/// Make an annotated commit from a reference.
///
/// @param reference The reference the annotated commit should point to. Must not be nil.
/// @param error     An error if one occurred.
///
/// @return Return a newly initialized instance of the receiver.
+ (nullable instancetype)annotatedCommitFromReference:(GTReference *)reference error:(NSError **)error;

/// Make an annotated commit from a fetch head.
///
/// @param branchName The branch name to use. Must not be nil.
/// @param remoteURL  The remote URL to use. Must not be nil.
/// @param OID        The OID the commit should point to. Must not be nil.
/// @param repository The repository the OID belongs to. Must not be nil.
/// @param error      An error if one occurred.
///
/// @return Return a newly initialized instance of the receiver.
+ (nullable instancetype)annotatedCommitFromFetchHead:(NSString *)branchName url:(NSString *)remoteURL oid:(GTOID *)OID inRepository:(GTRepository *)repository error:(NSError **)error;

/// Make an annotated commit from a OID.
///
/// @param OID        The OID the commit should point to. Must not be nil.
/// @param repository The repository the OID belongs to. Must not be nil.
/// @param error      An error if one occurred.
///
/// @return Return a newly initialized instance of the receiver.
+ (nullable instancetype)annotatedCommitFromOID:(GTOID *)OID inRepository:(GTRepository *)repository error:(NSError **)error;

/// Make an annotated commit by resolving a revspec.
///
/// @param revSpec    The revspec to resolve. Must not be nil.
/// @param repository The repository to perform the resolution in. Must not be nil.
/// @param error      An error if one occurred.
///
/// @return Return a newly initialized instance of the receiver.
+ (nullable instancetype)annotatedCommitFromRevSpec:(NSString *)revSpec inRepository:(GTRepository *)repository error:(NSError **)error;

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer
///
/// @param annotated_commit The annotated commit to wrap. Must not be nil.
///
/// @return Return a newly initialized instance of the receiver.
- (nullable instancetype)initWithGitAnnotatedCommit:(git_annotated_commit *)annotated_commit NS_DESIGNATED_INITIALIZER;

/// The underlying `git_annotated_commit` object.
- (git_annotated_commit *)git_annotated_commit __attribute__((objc_returns_inner_pointer));

/// The OID of the underlying commit.
@property (nonatomic, copy, readonly) GTOID *OID;

@end

NS_ASSUME_NONNULL_END
