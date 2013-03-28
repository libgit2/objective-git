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

// Creates a new `NSDate` from the provided `git_time`.
//
// time     - The `git_time` to base the returned date on.
// timeZone - The timezone used by the time passed in.
//
// Returns an `NSDate` object representing the passed in `time`. 
+ (NSDate *)gt_dateFromGitTime:(git_time)time timeZone:(NSTimeZone **)timeZone;

// Converts the date to a `git_time`.
//
// timeZone - An `NSTimeZone` to describe the time offset. This is optional, if
//            `nil` the default time zone will be used.
- (git_time)gt_gitTimeUsingTimeZone:(NSTimeZone *)timeZone;

@end

@interface NSTimeZone (GTTimeAdditions)

// The difference, in minutes, between the current default timezone and GMT.
@property (nonatomic, readonly) int gt_gitTimeOffset;

@end
