//
//  GTSubmoduleSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-05-29.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(GTSubmodule)

__block GTRepository *repo;

beforeEach(^{
	repo = [self fixtureRepositoryNamed:@"repo-with-submodule"];
	expect(repo).notTo.beNil();
});

it(@"should enumerate top-level submodules", ^{
	NSMutableSet *names = [NSMutableSet set];
	[repo enumerateSubmodulesRecursively:NO usingBlock:^(GTSubmodule *submodule, BOOL *stop) {
		expect(stop).notTo.beNil();

		expect(submodule).to.beKindOf(GTSubmodule.class);
		expect(submodule.name).notTo.beNil();

		[names addObject:submodule.name];
	}];

	NSSet *expectedNames = [NSSet setWithArray:@[ @"Archimedes", @"Test_App", @"Test_App2" ]];
	expect(names).to.equal(expectedNames);
});

it(@"should enumerate submodules recursively", ^{
	NSMutableSet *names = [NSMutableSet set];
	[repo enumerateSubmodulesRecursively:YES usingBlock:^(GTSubmodule *submodule, BOOL *stop) {
		expect(stop).notTo.beNil();

		expect(submodule).to.beKindOf(GTSubmodule.class);
		expect(submodule.name).notTo.beNil();

		[names addObject:submodule.name];
	}];

	NSSet *expectedNames = [NSSet setWithArray:@[ @"Archimedes", @"Configuration", @"ArchimedesTests/expecta", @"ArchimedesTests/specta", @"Test_App", @"Test_App2" ]];
	expect(names).to.equal(expectedNames);
});

it(@"should terminate enumeration early", ^{
	__block NSUInteger count = 0;
	[repo enumerateSubmodulesRecursively:NO usingBlock:^(GTSubmodule *submodule, BOOL *stop) {
		if (count == 2) {
			*stop = YES;
		} else {
			count++;
		}
	}];

	expect(count).to.equal(2);
});

SpecEnd
