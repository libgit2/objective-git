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
	it(@"should return nil for -remotes", ^{
		GTConfiguration *config = [GTConfiguration defaultConfiguration];
		expect(config).notTo.beNil();
		expect(config.remotes).to.beNil();
	});
});

SpecEnd
