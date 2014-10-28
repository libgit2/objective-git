//
//  GTTimeAdditionsSpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 27/03/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTTimeAdditions)

describe(@"Conversion between git_time and NSDate", ^{
	it(@"should be able to create a correct NSDate and NSTimeZone when given a git_time", ^{
		git_time_t seconds = 1265374800;
		int offset = -120; //2 hours behind GMT
		git_time time = (git_time){ .time = seconds, .offset = offset };
		NSDate *date = [NSDate gt_dateFromGitTime:time];
		expect(date).notTo(beNil());

		NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
		gregorianCalendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
		NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear | NSCalendarUnitHour fromDate:date];
		expect(components).notTo(beNil());

		expect(@(components.day)).to(equal(@5));
		expect(@(components.month)).to(equal(@2));
		expect(@(components.year)).to(equal(@2010));
		expect(@(components.hour)).to(equal(@13));

		NSTimeZone *timeZone = [NSTimeZone gt_timeZoneFromGitTime:time];
		expect(timeZone).notTo(beNil());
		NSInteger expectedSecondsFromGMT = -120 * 60;
		expect(@(timeZone.secondsFromGMT)).to(equal(@(expectedSecondsFromGMT)));
	});

	it(@"should return a correct offset for an NSTimeZone", ^{
		NSTimeZone *timeZone = [NSTimeZone timeZoneForSecondsFromGMT:180 * 60];
		expect(timeZone).notTo(beNil());
		expect(@(timeZone.gt_gitTimeOffset)).to(equal(@180));
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
