//
//  GTConfigurationSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/27/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTConfigurationSpec)

qck_describe(@"+defaultConfiguration", ^{
	static NSString * const testKey = @"universe.answer";
	static NSString * const testValue = @"42, probably";

	__block GTConfiguration *config;

	qck_beforeEach(^{
		config = [GTConfiguration defaultConfiguration];
		expect(config).notTo(beNil());
	});

	qck_it(@"should return nil for -remotes", ^{
		expect(config.remotes).to(beNil());
	});

	qck_it(@"should support reading and writing", ^{
		id value = [config stringForKey:testKey];
		expect(value).to(beNil());

		[config setString:testValue forKey:testKey];
		value = [config stringForKey:testKey];
		expect(value).to(equal(testValue));
	});

	qck_it(@"should support deletion", ^{
		[config setString:testValue forKey:testKey];
		id value = [config stringForKey:testKey];
		expect(value).notTo(beNil());

		BOOL success = [config deleteValueForKey:testKey error:NULL];
		expect(@(success)).to(beTruthy());

		value = [config stringForKey:testKey];
		expect(value).to(beNil());
	});
});

qck_afterEach(^{
	[self tearDown];
});

QuickSpecEnd
