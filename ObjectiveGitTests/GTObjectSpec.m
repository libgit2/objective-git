//
//  GTObjectSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/13/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTObject.h"
#import "GTRepository.h"

SpecBegin(GTObject)

describe(@"+objectWithRevisionString:repository:", ^{
	__block GTRepository *repository;

	beforeEach(^{
		repository = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:NULL];
		expect(repository).notTo.beNil();
	});

	it(@"should return the object represented by the string", ^{
		GTObject *object = [GTObject objectWithRevisionString:@"HEAD^" repository:repository error:NULL];
		expect(object.sha).to.equal(@"5b5b025afb0b4c913b4c338a42934a3863bf3644");
	});

	it(@"should return nil if there are no matches", ^{
		GTObject *object = [GTObject objectWithRevisionString:@"yourMom^" repository:repository error:NULL];
		expect(object).to.beNil();
	});
});

SpecEnd
