//
//  GTReflogEntry+Private.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTReflogEntry.h"

@interface GTReflogEntry ()

/// Initializes the receiver with the underlying reflog entry.
///
/// entry  - The reflog entry. Cannot be NULL.
/// reflog - The reflog in which the entry resides. Cannot be nil.
///
/// Returns the initialized object.
- (id)initWithGitReflogEntry:(const git_reflog_entry *)entry reflog:(GTReflog *)reflog;

@end
