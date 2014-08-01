//
//  GTObjectDatabaseSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 6/24/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTObjectDatabase.h"

SpecBegin(GTObjectDatabase)

__block GTObjectDatabase *database;

beforeEach(^{
	GTRepository *repo = self.bareFixtureRepository;
	expect(repo).notTo.beNil();

	database = [repo objectDatabaseWithError:NULL];
	expect(database).notTo.beNil();
});

it(@"should know what objects exist", ^{
	NSArray *existentSHAs = @[
		@"8496071c1b46c854b31185ea97743be6a8774479",
		@"1385f264afb75a56a5bec74243be9b367ba4ca08",
	];

	NSArray *nonExistentSHAs = @[
		@"ce08fe4884650f067bd5703b6a59a8b3b3c99a09",
		@"8496071c1c46c854b31185ea97743be6a8774479",
	];

	for (NSString *SHA in existentSHAs) {
		expect([database containsObjectWithSHA:SHA error:NULL]).to.beTruthy();
	}

	for (NSString *SHA in nonExistentSHAs) {
		expect([database containsObjectWithSHA:SHA error:NULL]).to.beFalsy();
	}
});

it(@"should be able to read an object", ^{
	GTOdbObject *object = [database objectWithSHA:@"8496071c1b46c854b31185ea97743be6a8774479" error:NULL];
	expect(object).notTo.beNil();
	expect(object.type).to.equal(GTObjectTypeCommit);

	NSData *data = object.data;
	expect(data).notTo.beNil();
	expect(data.length).to.equal(172);
	
	NSString *stringContents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	expect(stringContents).notTo.beNil();

	NSString *header = [stringContents substringToIndex:45];
	expect(header).to.equal(@"tree 181037049a54a1eb5fab404658a3a250b44335d7");
});

it(@"shouldn't be able to read a non-existent object", ^{
	GTOdbObject *object = [database objectWithSHA:@"a496071c1b46c854b31185ea97743be6a8774471" error:NULL];
	expect(object).to.beNil();
});

it(@"should be able to write", ^{
	static NSString * const testContent = @"my test data\n";
	static const GTObjectType testContentType = GTObjectTypeBlob;
	static NSString * const testContentSHA = @"76b1b55ab653581d6f2c7230d34098e837197674";
	GTOID *oid = [database writeData:[testContent dataUsingEncoding:NSUTF8StringEncoding] type:testContentType error:NULL];
	expect(oid.SHA).to.equal(testContentSHA);
	expect([database containsObjectWithSHA:testContentSHA error:NULL]).to.beTruthy();
});

afterEach(^{
	[self tearDown];
});

SpecEnd
