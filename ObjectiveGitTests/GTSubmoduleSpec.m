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

SpecEnd
