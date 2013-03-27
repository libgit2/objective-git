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
	NSInteger seconds = time.time;
	seconds += time.offset * 60;
	return [NSDate dateWithTimeIntervalSince1970:seconds];
}

- (git_time)gt_gitTime {
	return (git_time){.offset = self.gt_gitTimeOffset, .time = (git_time_t)[self timeIntervalSince1970]};
}

- (int)gt_gitTimeOffset {
	NSInteger timezoneOffset = [NSTimeZone.defaultTimeZone secondsFromGMT];
	int offset = (int)timezoneOffset / 60;
	return offset;
}

@end
