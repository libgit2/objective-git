//
//  GTFilterSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 2/14/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTFilter.h"

SpecBegin(GTFilter)

static NSString * const testFile = @"stuff.txt";
static NSString * const filterName = @"special-filter";
static NSString * const filterAttributes = @"special";

__block GTRepository *repository;
__block GTFilter *filter;

__block void (^addTestFileToIndex)(void);

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo.beNil();

	NSString *attributes = @"*.txt special\n";
	BOOL success = [attributes writeToURL:[repository.fileURL URLByAppendingPathComponent:@".gitattributes"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	expect(success).to.beTruthy();

	success = [@"some stuff" writeToURL:[repository.fileURL URLByAppendingPathComponent:testFile] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	expect(success).to.beTruthy();

	addTestFileToIndex = ^{
		GTIndex *index = [repository indexWithError:NULL];
		expect(index).notTo.beNil();

		BOOL success = [index addFile:@"stuff.txt" error:NULL];
		expect(success).to.beTruthy();

		success = [index write:NULL];
		expect(success).to.beTruthy();
	};
});

it(@"should call all the blocks", ^{
	__block BOOL initializeCalled = NO;
	__block BOOL checkCalled = NO;
	__block BOOL applyCalled = NO;
	__block BOOL cleanupCalled = NO;
	filter = [[GTFilter alloc] initWithName:filterName attributes:filterAttributes initializeBlock:^{
		initializeCalled = YES;
	} shutdownBlock:nil checkBlock:^(void **payload, GTFilterSource *source, const char **attr_values) {
		checkCalled = YES;
		return YES;
	} applyBlock:^(void **payload, NSData *from, NSData **to, GTFilterSource *source) {
		applyCalled = YES;
		return YES;
	} cleanupBlock:^(void *payload) {
		cleanupCalled = YES;
	}];

	BOOL success = [filter registerWithPriority:0 error:NULL];
	expect(success).to.beTruthy();

	addTestFileToIndex();

	expect(initializeCalled).to.beTruthy();
	expect(checkCalled).to.beTruthy();
	expect(applyCalled).to.beTruthy();
	expect(cleanupCalled).to.beTruthy();
});

it(@"shouldn't call the apply block if the check block returns NO", ^{
	__block BOOL applyCalled = NO;
	filter = [[GTFilter alloc] initWithName:filterName attributes:filterAttributes initializeBlock:nil shutdownBlock:nil checkBlock:^(void **payload, GTFilterSource *source, const char **attr_values) {
		return NO;
	} applyBlock:^(void **payload, NSData *from, NSData **to, GTFilterSource *source) {
		applyCalled = YES;
		return YES;
	} cleanupBlock:nil];

	BOOL success = [filter registerWithPriority:0 error:NULL];
	expect(success).to.beTruthy();

	addTestFileToIndex();

	expect(applyCalled).to.beFalsy();
});

it(@"should write the data set in the apply block", ^{
	NSData *replacementData = [@"oh hi mark" dataUsingEncoding:NSUTF8StringEncoding];
	filter = [[GTFilter alloc] initWithName:filterName attributes:filterAttributes initializeBlock:nil shutdownBlock:nil checkBlock:nil applyBlock:^(void **payload, NSData *from, NSData **to, GTFilterSource *source) {
		*to = replacementData;
		return YES;
	} cleanupBlock:nil];

	BOOL success = [filter registerWithPriority:0 error:NULL];
	expect(success).to.beTruthy();

	addTestFileToIndex();

	GTIndex *index = [repository indexWithError:NULL];
	GTTree *tree = [index writeTree:NULL];
	GTTreeEntry *entry = [tree entryWithName:testFile];
	GTOdbObject *ODBObject = [[entry GTObject:NULL] odbObjectWithError:NULL];
	expect(ODBObject.data).to.equal(replacementData);
});

afterEach(^{
	BOOL success = [filter unregister:NULL];
	expect(success).to.beTruthy();
});

SpecEnd
