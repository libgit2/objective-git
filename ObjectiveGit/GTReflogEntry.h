//
//  GTReflogEntry.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GTOID;
@class GTSignature;

/// An entry in a GTReflog.
@interface GTReflogEntry : NSObject

/// The OID of the ref before the entry.
@property (nonatomic, readonly, strong) GTOID * _Nullable previousOID;

/// The OID of the ref when the entry was made.
@property (nonatomic, readonly, strong) GTOID * _Nullable updatedOID;

/// The person who committed the entry.
@property (nonatomic, readonly, strong) GTSignature * _Nullable committer;

/// The message associated with the entry.
@property (nonatomic, readonly, copy) NSString * _Nullable message;

@end
