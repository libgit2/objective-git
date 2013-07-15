//
//  GTTreeSpec.m
//  ObjectiveGitFramework
//
//  Created by Johnnie Walker on 17/05/2013.
//  Copyright (c) 2013 Johnnie Walker
//

#import "GTTree.h"
#import "GTTreeEntry.h"
#import "GTTreeBuilder.h"
#import "GTRepository.h"
#import "GTBlob.h"
#import "git2.h"

static NSString * const testTreeSHA = @"c4dc1555e4d4fa0e0c9c3fc46734c7c35b3ce90b";

SpecBegin(GTTreeBuilder)

it(@"should be possible to make a new tree builder without a tree", ^{
	NSError *error = nil;
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
	expect(error).to.beNil();
	expect(builder).notTo.beNil();
});

it(@"should be possible to make a new tree builder from an existing tree", ^{
	NSError *error = nil;
	
	GTRepository *repo = [self fixtureRepositoryNamed:@"testrepo.git"];
	expect(repo).notTo.beNil();
	
	GTTree *tree = (GTTree *)[repo lookupObjectBySHA:testTreeSHA error:NULL];
	expect(tree).notTo.beNil();
	
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:tree error:&error];
	expect(error).to.beNil();
	expect(builder).notTo.beNil();
});

describe(@"GTTreeBuilder building", ^{
	__block GTTreeBuilder *builder;
	__block NSError *error = nil;
	
	beforeEach(^{
		builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
		expect(builder).notTo.beNil();
		expect(error).to.beNil();
	});
	
	it(@"should be possible to add an entry to a builder", ^{
		GTTreeEntry *entry = [builder addEntryWithSHA:testTreeSHA filename:@"tree" filemode:GTFileModeTree error:&error];
		expect(entry).notTo.beNil();
		expect(error).to.beNil();
		
		expect(builder.entryCount).to.equal(1);
	});
	
	it(@"should be possible to remove an entry from a builder", ^{
		NSString *filename = @"tree";
		GTTreeEntry *entry = [builder addEntryWithSHA:testTreeSHA filename:filename filemode:GTFileModeTree error:&error];
		expect(entry).notTo.beNil();
		expect(error).to.beNil();
		
		expect(builder.entryCount).to.equal(1);
		
		BOOL success = [builder removeEntryWithFilename:filename error:&error];
		expect(success).to.beTruthy();
		expect(error).to.beNil();
		
		expect(builder.entryCount).to.equal(0);
	});
	
	it(@"should be possible to filter a builder", ^{	
		GTRepository *repo = [self fixtureRepositoryNamed:@"testrepo.git"];
		expect(repo).notTo.beNil();
		
		GTBlob *blob = [GTBlob blobWithString:@"Hi, how are you?" inRepository:repo error:&error];
		expect(blob).notTo.beNil();
		expect(error).to.beNil();
		
		[builder addEntryWithSHA:blob.SHA filename:@"hi.txt" filemode:GTFileModeBlob error:&error];
		
		expect(builder.entryCount).to.equal(1);
		
		[builder filter:^(const git_tree_entry *entry) {
			return YES;
		}];
		
		expect(builder.entryCount).to.equal(0);
	});

	it(@"should be possible to find an entry by file name in a builder", ^{
		NSString *filename = @"tree";
		GTTreeEntry *entry = [builder addEntryWithSHA:testTreeSHA filename:filename filemode:GTFileModeTree error:&error];
		expect(entry).notTo.beNil();
		expect(error).to.beNil();
		
		GTTreeEntry *foundEntry = [builder entryWithName:filename];
		expect(foundEntry.SHA).to.equal(entry.SHA);
	});

	it(@"should be possible to write a builder to a repository", ^{
		GTRepository *repo = [self fixtureRepositoryNamed:@"testrepo.git"];
		expect(repo).notTo.beNil();
		
		GTBlob *blob = [GTBlob blobWithString:@"Hi, how are you?" inRepository:repo error:&error];
		expect(blob).notTo.beNil();
		expect(error).to.beNil();
		
		[builder addEntryWithSHA:blob.SHA filename:@"hi.txt" filemode:GTFileModeBlob error:&error];
		
		GTTree *writtenTree = [builder writeTreeToRepository:repo error:&error];
		expect(writtenTree).notTo.beNil();
		expect(error).to.beNil();
		
		GTTree *readTree = (GTTree *)[repo lookupObjectBySHA:writtenTree.SHA objectType:GTObjectTypeTree error:&error];
		expect(readTree).notTo.beNil();
		expect(error).to.beNil();
		
	});
});

SpecEnd
