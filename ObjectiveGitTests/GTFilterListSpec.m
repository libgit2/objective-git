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

__block GTRepository *repository;

__block GTFilter *readFilter;
__block GTFilter *textFilter;

NSString *readFilterContent = @"\nthis was touched by the read-filter!";
NSString *textFilterContent = @"\nohai text-filter!";

beforeEach(^{
	repository = self.testAppFixtureRepository;

	NSString *attributes = @"READ* rf=true\n*.txt tf=true\n";
	BOOL success = [attributes writeToURL:[repository.fileURL URLByAppendingPathComponent:@".gitattributes"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	expect(success).to.beTruthy();

	readFilter = [[GTFilter alloc] initWithName:@"read-filter" attributes:@"rf=true" applyBlock:^(void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
		NSMutableData *buffer = [from mutableCopy];
		[buffer appendData:[readFilterContent dataUsingEncoding:NSUTF8StringEncoding]];

		return buffer;
	}];

	expect(readFilter).notTo.beNil();
	expect([readFilter registerWithPriority:1 error:NULL]).to.beTruthy();

	textFilter = [[GTFilter alloc] initWithName:@"text-filter" attributes:@"tf=true" applyBlock:^(void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
		NSMutableData *buffer = [from mutableCopy];
		[buffer appendData:[textFilterContent dataUsingEncoding:NSUTF8StringEncoding]];

		return buffer;
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
		GTFilterList *list = [repository filterListWithPath:@"TestAppDelegate.h" blob:nil mode:GTFilterSourceModeSmudge options:GTFilterListOptionsDefault success:&success error:&error];
		expect(list).to.beNil();
		expect(success).to.beTruthy();
		expect(error).to.beNil();
	});

	it(@"should return non-nil on a path with a single filter", ^{
		GTFilterList *list = [repository filterListWithPath:@"README.md" blob:nil mode:GTFilterSourceModeSmudge options:GTFilterListOptionsDefault success:&success error:&error];
		expect(list).notTo.beNil();
		expect(success).to.beTruthy();
		expect(error).to.beNil();
	});

	it(@"should return non-nil on a path with multiple filters", ^{
		GTFilterList *list = [repository filterListWithPath:@"README1.txt" blob:nil mode:GTFilterSourceModeSmudge options:GTFilterListOptionsDefault success:&success error:&error];
		expect(list).notTo.beNil();
		expect(success).to.beTruthy();
		expect(error).to.beNil();
	});

	it(@"should return non-nil on a nonexistent path with a blob", ^{
		NSData *data = [@"haters gonna haaaate" dataUsingEncoding:NSUTF8StringEncoding];
		GTBlob *blob = [[GTBlob alloc] initWithData:data inRepository:repository error:NULL];
		expect(blob).notTo.beNil();

		GTFilterList *list = [repository filterListWithPath:@"haters-gonna-hate.txt" blob:blob mode:GTFilterSourceModeClean options:GTFilterListOptionsDefault success:&success error:&error];
		expect(list).notTo.beNil();
		expect(success).to.beTruthy();
		expect(error).to.beNil();
	});
});

it(@"should apply a single filter", ^{
	GTFilterList *list = [repository filterListWithPath:@"README.md" blob:nil mode:GTFilterSourceModeSmudge options:GTFilterListOptionsDefault success:NULL error:NULL];
	expect(list).notTo.beNil();

	NSString *inputString = @"foobar";

	NSError *error = nil;
	NSData *result = [list applyToData:[inputString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
	expect(result).notTo.beNil();
	expect(error).to.beNil();

	NSString *resultString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
	expect(resultString).to.contain(inputString);
	expect(resultString).to.contain(readFilterContent);
	expect(resultString).notTo.contain(textFilterContent);
});

describe(@"applying a list of multiple filters", ^{
	__block GTFilterList *list;

	beforeEach(^{
		// This file should have `readFilter` applied first, then `textFilter`.
		list = [repository filterListWithPath:@"README1.txt" blob:nil mode:GTFilterSourceModeSmudge options:GTFilterListOptionsDefault success:NULL error:NULL];
		expect(list).notTo.beNil();
	});

	afterEach(^{
		// Make sure the list is torn down before the repository.
		list = nil;
	});

	it(@"should apply to data", ^{
		NSString *inputString = @"foobar";

		NSError *error = nil;
		NSData *result = [list applyToData:[inputString dataUsingEncoding:NSUTF8StringEncoding] error:&error];
		expect(result).notTo.beNil();
		expect(error).to.beNil();

		NSString *resultString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
		expect(resultString).to.contain(inputString);
		expect(resultString).to.contain(readFilterContent);
		expect(resultString).to.contain(textFilterContent);
	});

	it(@"should apply to a file", ^{
		NSString *inputFilename = @"README";
		GTRepository *inputRepo = self.conflictedFixtureRepository;

		NSString *content = [NSString stringWithContentsOfURL:[inputRepo.fileURL URLByAppendingPathComponent:inputFilename] encoding:NSUTF8StringEncoding error:NULL];
		expect(content).notTo.contain(readFilterContent);
		expect(content).notTo.contain(textFilterContent);

		NSError *error = nil;
		NSData *result = [list applyToPath:inputFilename inRepository:inputRepo error:&error];
		expect(result).notTo.beNil();
		expect(error).to.beNil();

		NSString *resultString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
		expect(resultString).to.contain(content);
		expect(resultString).to.contain(readFilterContent);
		expect(resultString).to.contain(textFilterContent);
	});

	it(@"should apply to a blob", ^{
		// This is `REAME_` from `HEAD`.
		GTBlob *blob = [repository lookUpObjectBySHA:@"8b4a21733703ca50b96186691615e8d2f6314e79" objectType:GTObjectTypeBlob error:NULL];
		expect(blob).notTo.beNil();

		expect(blob.content).notTo.beNil();
		expect(blob.content).notTo.contain(readFilterContent);
		expect(blob.content).notTo.contain(textFilterContent);

		NSError *error = nil;
		NSData *result = [list applyToBlob:blob error:&error];
		expect(result).notTo.beNil();
		expect(error).to.beNil();

		NSString *resultString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
		expect(resultString).to.contain(blob.content);
		expect(resultString).to.contain(readFilterContent);
		expect(resultString).to.contain(textFilterContent);
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
