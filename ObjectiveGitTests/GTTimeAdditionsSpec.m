//
//  GTTimeAdditionsSpec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 27/03/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSDate+GTTimeAdditions.h"

SpecBegin(GTTimeAdditions)

describe(@"Convertion between git_time and NSDate", ^{
	it(@"should be able to create an NSDate when given a git_time", ^{
		git_time_t seconds = 1265374800;
		int offset = -120; //2 hours behind GMT
		git_time time = (git_time){ .time = seconds, .offset = offset };
		NSDate *date = [NSDate gt_dateFromGitTime:time];
		expect(date).toNot.beNil();
		
		NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
		NSDateComponents *components = [gregorianCalendar components:NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit fromDate:date];
		expect(components).toNot.beNil();
		
		expect(components.day).to.equal(5);
		expect(components.month).to.equal(2);
		expect(components.year).to.equal(2010);
		expect(components.hour).to.equal(11);
	});
});

SpecEnd
