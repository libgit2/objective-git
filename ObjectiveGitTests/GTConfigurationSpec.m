//
//  GTConfigurationSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/27/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTConfiguration.h"

SpecBegin(GTConfiguration)

static NSString * const testKey = @"universe.answer";
static NSString * const testValue = @"42, probably";

__block GTConfiguration *config;

describe(@"+defaultConfiguration", ^{
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

fdescribe(@"-initWithPath:error:", ^{
	beforeEach(^{
		NSString *rawConfig = @"[test]\n\tname = josh\n";
		NSString *path = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"config.ini"].path;
		BOOL success = [rawConfig writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL];
		expect(success).to.beTruthy();

		config = [[GTConfiguration alloc] initWithPath:path error:NULL];
		expect(config).notTo.beNil();
	});

	it(@"should be able to read values", ^{
		expect([config stringForKey:@"test.name"]).to.equal(@"josh");
	});

	it(@"should be able to write values", ^{
		[config setString:testValue forKey:testKey];
		expect([config stringForKey:testKey]).to.equal(testValue);
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
