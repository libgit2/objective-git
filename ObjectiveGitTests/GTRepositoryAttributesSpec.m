//
//  GTRepositoryAttributesSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 7/25/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTRepositoryAttributes)

__block GTRepository *repository;

beforeEach(^{
	repository = [self blankFixtureRepository];
});

it(@"should be able to look up attributes", ^{
	static NSString * const testAttributes = @"*.txt filter=reverse";
	NSURL *attributesURL = [repository.fileURL URLByAppendingPathComponent:@".gitattributes"];
	BOOL success = [testAttributes writeToURL:attributesURL atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	expect(@(success)).to(beTruthy());

	NSString *value = [repository attributeWithName:@"filter" path:@"*.txt"];
	expect(value).to(equal(@"reverse"));

	value = [repository attributeWithName:@"filter" path:@"thing.txt"];
	expect(value).to(equal(@"reverse"));

	value = [repository attributeWithName:@"filter" path:@"thing.jpg"];
	expect(value).to(beNil());
});

QuickSpecEnd
