//
//  NSDate+GTTimeAdditions.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 27/03/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "git2.h"

@interface NSDate (GTTimeAdditions)

// The date represented as a `git_time`.
@property (nonatomic, readonly) git_time gt_gitTime;

// The difference, in minutes, between the current default timezone and GMT. 
@property (nonatomic, readonly) int gt_gitTimeOffset;

// Creates a new `NSDate` from the provided `git_time`.
//
// Note: the date will take into account the timezone offset and return a date
//       as it was in the source timezone. This matches output from the likes of
//       `git log`.
+ (NSDate *)gt_dateFromGitTime:(git_time)time;

@end
