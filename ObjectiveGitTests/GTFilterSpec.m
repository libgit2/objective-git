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

typedef NSData * (^GTFilterApplyBlock)(void **payload, NSData *from, GTFilterSource *source, BOOL *applied);

__block void (^setUpFilterWithApplyBlock)(GTFilterApplyBlock block);

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo.beNil();

	NSString *attributes = @"*.txt special\n";
	BOOL success = [attributes writeToURL:[repository.fileURL URLByAppendingPathComponent:@".gitattributes"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	expect(success).to.beTruthy();

	success = [@"some stuff" writeToURL:[repository.fileURL URLByAppendingPathComponent:testFile] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	expect(success).to.beTruthy();

	setUpFilterWithApplyBlock = ^(GTFilterApplyBlock applyBlock) {
		applyBlock = applyBlock ?: ^ NSData * (void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
			return nil;
		};

		filter = [[GTFilter alloc] initWithName:filterName attributes:filterAttributes applyBlock:applyBlock];

		BOOL success = [filter registerWithPriority:0 error:NULL];
		expect(success).to.beTruthy();
	};

	addTestFileToIndex = ^{
		GTIndex *index = [repository indexWithError:NULL];
		expect(index).notTo.beNil();

		BOOL success = [index addFile:@"stuff.txt" error:NULL];
		expect(success).to.beTruthy();

		success = [index write:NULL];
		expect(success).to.beTruthy();
	};
});

afterEach(^{
	BOOL success = [filter unregister:NULL];
	expect(success).to.beTruthy();
});

it(@"should be able to look up a registered filter by name", ^{
	setUpFilterWithApplyBlock(nil);
	GTFilter *filter = [GTFilter filterForName:filterName];
	expect(filter).notTo.beNil();
});

it(@"should call all the blocks", ^{
	__block BOOL initializeCalled = NO;
	__block BOOL checkCalled = NO;
	__block BOOL applyCalled = NO;
	__block BOOL cleanupCalled = NO;
	setUpFilterWithApplyBlock(^ NSData * (void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
		applyCalled = YES;
		return nil;
	});

	filter.initializeBlock = ^{
		initializeCalled = YES;
	};

	filter.checkBlock = ^(void **payload, GTFilterSource *source, const char **attr_values) {
		checkCalled = YES;
		return YES;
	};

	filter.cleanupBlock = ^(void *payload) {
		cleanupCalled = YES;
	};

	addTestFileToIndex();

	expect(initializeCalled).to.beTruthy();
	expect(checkCalled).to.beTruthy();
	expect(applyCalled).to.beTruthy();
	expect(cleanupCalled).to.beTruthy();
});

it(@"shouldn't call the apply block if the check block returns NO", ^{
	__block BOOL applyCalled = NO;
	setUpFilterWithApplyBlock(^ NSData * (void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
		applyCalled = YES;
		return nil;
	});

	filter.checkBlock = ^(void **payload, GTFilterSource *source, const char **attr_values) {
		return NO;
	};

	addTestFileToIndex();

	expect(applyCalled).to.beFalsy();
});

describe(@"application", ^{
	it(@"should write the data returned by the apply block when cleaned", ^{
		NSData *replacementData = [@"oh hi mark" dataUsingEncoding:NSUTF8StringEncoding];
		setUpFilterWithApplyBlock(^(void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
			return replacementData;
		});

		addTestFileToIndex();

		GTIndex *index = [repository indexWithError:NULL];
		GTTree *tree = [index writeTree:NULL];
		GTTreeEntry *entry = [tree entryWithName:testFile];
		GTOdbObject *ODBObject = [[entry GTObject:NULL] odbObjectWithError:NULL];
		expect(ODBObject.data).to.equal(replacementData);
	});

	it(@"should write the data returned by the apply block when smudged", ^{
		addTestFileToIndex();
		GTIndex *index = [repository indexWithError:NULL];
		GTTree *tree = [index writeTree:NULL];
		expect(tree).notTo.beNil();

		GTReference *HEADRef = [repository headReferenceWithError:NULL];
		expect(HEADRef).notTo.beNil();

		GTCommit *HEADCommit = HEADRef.resolvedTarget;
		expect(HEADCommit).notTo.beNil();

		GTCommit *newCommit = [repository createCommitWithTree:tree message:@"" parents:@[ HEADCommit ] updatingReferenceNamed:HEADRef.name error:NULL];
		expect(newCommit).notTo.beNil();

		NSData *replacementData = [@"you're my favorite customer" dataUsingEncoding:NSUTF8StringEncoding];
		setUpFilterWithApplyBlock(^(void **payload, NSData *from, GTFilterSource *source, BOOL *applied) {
			return replacementData;
		});

		NSURL *testFileURL = [repository.fileURL URLByAppendingPathComponent:testFile];
		BOOL success = [NSFileManager.defaultManager removeItemAtURL:testFileURL error:NULL];
		expect(success).to.beTruthy();

		success = [repository checkoutCommit:newCommit strategy:GTCheckoutStrategyForce error:NULL progressBlock:NULL];
		expect(success).to.beTruthy();

		expect([NSData dataWithContentsOfURL:testFileURL]).to.equal(replacementData);
	});
});

it(@"should include the right filter source", ^{
	setUpFilterWithApplyBlock(nil);

	__block GTFilterSource *filterSource;
	filter.checkBlock = ^(void **payload, GTFilterSource *source, const char **attr_values) {
		filterSource = source;
		return NO;
	};

	addTestFileToIndex();

	expect(filterSource).notTo.beNil();
	expect(filterSource.path).to.equal(testFile);
	expect(filterSource.mode).to.equal(GTFilterSourceModeClean);
	expect(filterSource.repositoryURL).to.equal(repository.fileURL);
});

afterEach(^{
	[self tearDown];
});

SpecEnd
