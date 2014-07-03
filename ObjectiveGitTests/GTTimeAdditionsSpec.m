//
//  GTTimeAdditionsSpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 27/03/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSDate+GTTimeAdditions.h"

SpecBegin(GTTimeAdditions)

describe(@"Conversion between git_time and NSDate", ^{
	it(@"should be able to create a correct NSDate and NSTimeZone when given a git_time", ^{
		git_time_t seconds = 1265374800;
		int offset = -120; //2 hours behind GMT
		git_time time = (git_time){ .time = seconds, .offset = offset };
		NSDate *date = [NSDate gt_dateFromGitTime:time];
		expect(date).toNot.beNil();
		
		NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		gregorianCalendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		NSDateComponents *components = [gregorianCalendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit fromDate:date];
		expect(components).toNot.beNil();
		
		expect(components.day).to.equal(5);
		expect(components.month).to.equal(2);
		expect(components.year).to.equal(2010);
		expect(components.hour).to.equal(13);
		
		NSTimeZone *timeZone = [NSTimeZone gt_timeZoneFromGitTime:time];
		expect(timeZone).toNot.beNil();
		NSInteger expectedSecondsFromGMT = -120 * 60;
		expect(timeZone.secondsFromGMT).to.equal(expectedSecondsFromGMT);
	});
	
	it(@"should return a correct offset for an NSTimeZone", ^{
		NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:180 * 60];
		expect(timeZone).toNot.beNil();
		expect(timeZone.gt_gitTimeOffset).to.equal(180);
	});
	
	it(@"should return a correct git_time for an NSDate", ^{
		NSDate *date = [NSDate dateWithString:@"2010-05-12 18:29:13 +0000"];
		expect(date).toNot.beNil();
		
		NSTimeZone *twoHoursAheadOfGMT = [NSTimeZone timeZoneForSecondsFromGMT:120 * 60];
		git_time time = [date gt_gitTimeUsingTimeZone:twoHoursAheadOfGMT];
		expect(time.time).to.equal(1273688953);
		expect(time.offset).to.equal(120);
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
