//
//  NSDate+GTTimeAdditions.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 27/03/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSDate+GTTimeAdditions.h"

@implementation NSDate (GTTimeAdditions)

+ (NSDate *)gt_dateFromGitTime:(git_time)time {
	return [NSDate dateWithTimeIntervalSince1970:time.time];
}

- (git_time)gt_gitTimeUsingTimeZone:(NSTimeZone *)timeZone {
	NSTimeZone *correctedTimeZone = timeZone ?: NSTimeZone.defaultTimeZone;
	return (git_time){ .offset = correctedTimeZone.gt_gitTimeOffset, .time = (git_time_t)self.timeIntervalSince1970 };
}

@end

@implementation NSTimeZone (GTTimeAdditions)

+ (NSTimeZone *)gt_timeZoneFromGitTime:(git_time)time {
	return [NSTimeZone timeZoneForSecondsFromGMT:time.offset * 60];
}

- (int)gt_gitTimeOffset {
	NSInteger timezoneOffset = self.secondsFromGMT;
	int offset = (int)timezoneOffset / 60;
	return offset;
}

@end
