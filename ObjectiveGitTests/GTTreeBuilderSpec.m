//
//  GTTreeSpec.m
//  ObjectiveGitFramework
//
//  Created by Johnnie Walker on 17/05/2013.
//  Copyright (c) 2013 Johnnie Walker
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

static NSString * const testTreeSHA = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";

QuickSpecBegin(GTTreeBuilderSpec)

__block GTRepository *repo;

beforeEach(^{
	repo = self.bareFixtureRepository;
	expect(repo).notTo(beNil());
});

it(@"should be possible to make a new tree builder without a tree", ^{
	NSError *error = nil;
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil repository:repo error:&error];
	expect(error).to(beNil());
	expect(builder).notTo(beNil());
});

it(@"should be possible to make a new tree builder from an existing tree", ^{
	NSError *error = nil;

	GTTree *tree = (GTTree *)[repo lookUpObjectBySHA:testTreeSHA error:NULL];
	expect(tree).notTo(beNil());

	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:tree repository:repo error:&error];
	expect(error).to(beNil());
	expect(builder).notTo(beNil());
});

describe(@"GTTreeBuilder building", ^{
	__block GTTreeBuilder *builder;
	__block NSError *error = nil;
	__block GTOID *OID;

	beforeEach(^{
		builder = [[GTTreeBuilder alloc] initWithTree:nil repository:repo error:&error];
		expect(builder).notTo(beNil());
		expect(error).to(beNil());

		OID = [GTOID oidWithSHA:testTreeSHA];
	});

	it(@"should be possible to add an entry to a builder", ^{
		GTTreeEntry *entry = [builder addEntryWithOID:OID fileName:@"tree" fileMode:GTFileModeTree error:&error];
		expect(entry).notTo(beNil());
		expect(error).to(beNil());

		expect(@(builder.entryCount)).to(equal(@1));
	});

	it(@"should be possible to remove an entry from a builder", ^{
		NSString *fileName = @"tree";
		GTTreeEntry *entry = [builder addEntryWithOID:OID fileName:fileName fileMode:GTFileModeTree error:&error];
		expect(entry).notTo(beNil());
		expect(error).to(beNil());

		expect(@(builder.entryCount)).to(equal(@1));

		BOOL success = [builder removeEntryWithFileName:fileName error:&error];
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());

		expect(@(builder.entryCount)).to(equal(@0));
	});

	it(@"should be possible to filter a builder", ^{
		GTBlob *blob = [GTBlob blobWithString:@"Hi, how are you?" inRepository:repo error:&error];
		expect(blob).notTo(beNil());
		expect(error).to(beNil());

		[builder addEntryWithOID:blob.OID fileName:@"hi.txt" fileMode:GTFileModeBlob error:&error];

		expect(@(builder.entryCount)).to(equal(@1));

		[builder filter:^(const git_tree_entry *entry) {
			return YES;
		}];

		expect(@(builder.entryCount)).to(equal(@0));
	});

	it(@"should be possible to find an entry by file name in a builder", ^{
		NSString *fileName = @"tree";
		GTTreeEntry *entry = [builder addEntryWithOID:OID fileName:fileName fileMode:GTFileModeTree error:&error];
		expect(entry).notTo(beNil());
		expect(error).to(beNil());

		GTTreeEntry *foundEntry = [builder entryWithFileName:fileName];
		expect(foundEntry.SHA).to(equal(entry.SHA));
	});

	it(@"should be possible to write a blob with data", ^{
		GTTreeEntry *entry = [builder addEntryWithData:[@"Hello, World!" dataUsingEncoding:NSUTF8StringEncoding] fileName:@"test.txt" fileMode:GTFileModeBlob error:NULL];
		expect(entry).notTo(beNil());

		GTObjectDatabase *database = [repo objectDatabaseWithError:NULL];
		expect(database).notTo(beNil());

		expect(@([database containsObjectWithOID:entry.OID])).to(beTruthy());

		GTTree *tree = [builder writeTree:NULL];
		expect(tree).notTo(beNil());
	});

	it(@"should be possible to write a builder to a repository", ^{
		GTBlob *blob = [GTBlob blobWithString:@"Hi, how are you?" inRepository:repo error:&error];
		expect(blob).notTo(beNil());
		expect(error).to(beNil());

		[builder addEntryWithOID:blob.OID fileName:@"hi.txt" fileMode:GTFileModeBlob error:&error];

		GTTree *writtenTree = [builder writeTree:&error];
		expect(writtenTree).notTo(beNil());
		expect(error).to(beNil());

		GTTree *readTree = (GTTree *)[repo lookUpObjectBySHA:writtenTree.SHA objectType:GTObjectTypeTree error:&error];
		expect(readTree).notTo(beNil());
		expect(error).to(beNil());
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
