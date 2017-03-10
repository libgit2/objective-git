//
//  GTReflogEntry+Private.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTReflogEntry.h"
#import "git2/types.h"

NS_ASSUME_NONNULL_BEGIN

@interface GTReflogEntry ()

/// Initializes the receiver with the underlying reflog entry. Designated initializer.
///
/// entry  - The reflog entry. Cannot be NULL.
/// reflog - The reflog in which the entry resides. Cannot be nil.
///
/// Returns the initialized object.
- (instancetype _Nullable)initWithGitReflogEntry:(const git_reflog_entry *)entry reflog:(GTReflog *)reflog NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END