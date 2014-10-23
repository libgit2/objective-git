//
//  GTFetchHeadEntry.h
//  ObjectiveGitFramework
//
//  Created by Pablo Bendersky on 8/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTRepository;
@class GTOID;
@class GTReference;

/// A class representing an entry on the FETCH_HEAD file, as returned by the callback of git_repository_fetchhead_foreach.
@interface GTFetchHeadEntry : NSObject

/// The reference of this fetch entry.
@property (nonatomic, readonly, strong) GTReference *reference;

/// The remote URL where this entry was originally fetched from.
@property (nonatomic, readonly, copy) NSString *remoteURLString;

/// The target OID of this fetch entry (what we need to merge with)
@property (nonatomic, readonly, copy) GTOID *targetOID;

/// Flag indicating if we need to merge this entry or not.
@property (nonatomic, getter = isMerge, readonly) BOOL merge;

/// Initializes a GTFetchHeadEntry.
///
/// reference       - Reference on the repository. Cannot be nil.
/// remoteURLString - URL String where this was originally fetched from. Cannot be nil.
/// targetOID       - Target OID. Cannot be nil.
/// merge           - Indicates if this is pending a merge.
- (instancetype)initWithReference:(GTReference *)reference remoteURLString:(NSString *)remoteURLString targetOID:(GTOID *)targetOID isMerge:(BOOL)merge;

@end
