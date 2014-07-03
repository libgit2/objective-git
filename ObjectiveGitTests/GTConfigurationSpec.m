//
//  GTConfigurationSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/27/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTConfiguration.h"

SpecBegin(GTConfiguration)

describe(@"+defaultConfiguration", ^{
	static NSString * const testKey = @"universe.answer";
	static NSString * const testValue = @"42, probably";

	__block GTConfiguration *config;

	beforeEach(^{
		config = [GTConfiguration defaultConfiguration];
		expect(config).notTo.beNil();
	});

	it(@"should return nil for -remotes", ^{
		expect(config.remotes).to.beNil();
	});

	it(@"should support reading and writing", ^{
		id value = [config stringForKey:testKey];
		expect(value).to.beNil();

		[config setString:testValue forKey:testKey];
		value = [config stringForKey:testKey];
		expect(value).to.equal(testValue);
	});

	it(@"should support deletion", ^{
		[config setString:testValue forKey:testKey];
		id value = [config stringForKey:testKey];
		expect(value).notTo.beNil();

		BOOL success = [config deleteValueForKey:testKey error:NULL];
		expect(success).to.beTruthy();

		value = [config stringForKey:testKey];
		expect(value).to.beNil();
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
