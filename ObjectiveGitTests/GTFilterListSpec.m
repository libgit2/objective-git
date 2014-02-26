//
//  GTFilterListSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2014-02-26.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFilter.h"
#import "GTFilterList.h"

SpecBegin(GTFilterList)

__block GTFilter *readFilter;
__block NSData *readFilterResult;

__block GTFilter *textFilter;
__block NSData *textFilterResult;

__block GTRepository *repository;

beforeEach(^{
	repository = self.testAppFixtureRepository;

	NSString *attributes = @"READ* filter=read-filter\n*.txt filter=text-filter\n";
	BOOL success = [attributes writeToURL:[repository.fileURL URLByAppendingPathComponent:@".gitattributes"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	expect(success).to.beTruthy();

	textFilterResult = [@"filtered text" dataUsingEncoding:NSUTF8StringEncoding];
	readFilterResult = [@"filtered" dataUsingEncoding:NSUTF8StringEncoding];

	readFilter = [[GTFilter alloc] initWithName:@"read-filter" attributes:@"filter=read-filter" applyBlock:^(void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
		return readFilterResult;
	}];

	expect(readFilter).notTo.beNil();
	expect([readFilter registerWithPriority:1 error:NULL]).to.beTruthy();

	textFilter = [[GTFilter alloc] initWithName:@"text-filter" attributes:@"filter=text-filter" applyBlock:^(void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
		return textFilterResult;
	}];

	expect(textFilter).notTo.beNil();
	expect([textFilter registerWithPriority:0 error:NULL]).to.beTruthy();
});

afterEach(^{
	expect([readFilter unregister:NULL]).to.beTruthy();
	expect([textFilter unregister:NULL]).to.beTruthy();
});

describe(@"loading a filter list", ^{
	__block BOOL success;
	__block NSError *error;

	beforeEach(^{
		success = NO;
		error = nil;
	});

	it(@"should return nil on a path without any filters", ^{
		GTFilterList *list = [repository filterListWithPath:@"TestAppDelegate.h" blob:nil mode:GTFilterSourceModeSmudge success:&success error:&error];
		expect(list).to.beNil();
		expect(success).to.beTruthy();
		expect(error).to.beNil();
	});

	it(@"should return non-nil on a path with a single filter", ^{
		GTFilterList *list = [repository filterListWithPath:@"README.md" blob:nil mode:GTFilterSourceModeSmudge success:&success error:&error];
		expect(list).notTo.beNil();
		expect(success).to.beTruthy();
		expect(error).to.beNil();
	});

	it(@"should return non-nil on a path with multiple filters", ^{
		GTFilterList *list = [repository filterListWithPath:@"README1.txt" blob:nil mode:GTFilterSourceModeSmudge success:&success error:&error];
		expect(list).notTo.beNil();
		expect(success).to.beTruthy();
		expect(error).to.beNil();
	});

	it(@"should return non-nil on a nonexistent path with a blob", ^{
		NSData *data = [@"haters gonna haaaate" dataUsingEncoding:NSUTF8StringEncoding];
		GTBlob *blob = [[GTBlob alloc] initWithData:data inRepository:repository error:NULL];
		expect(blob).notTo.beNil();

		GTFilterList *list = [repository filterListWithPath:@"haters-gonna-hate.txt" blob:blob mode:GTFilterSourceModeClean success:&success error:&error];
		expect(list).notTo.beNil();
		expect(success).to.beTruthy();
		expect(error).to.beNil();
	});
});

it(@"should apply a single filter", ^{
	GTFilterList *list = [repository filterListWithPath:@"README.md" blob:nil mode:GTFilterSourceModeSmudge success:NULL error:NULL];
	expect(list).notTo.beNil();

	NSError *error = nil;
	NSData *result = [list applyToData:[NSData data] error:&error];
	expect(result).to.equal(readFilterResult);
	expect(error).to.beNil();
});

SpecEnd
