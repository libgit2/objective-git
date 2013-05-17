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

int filter_callback(const git_tree_entry *entry, void *payload);
int filter_callback(const git_tree_entry *entry, void *payload) {
	return 1;
};

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
	
	GTTree *tree = (GTTree *)[repo lookupObjectBySha:testTreeSHA error:NULL];
	expect(tree).notTo.beNil();
	
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:tree error:&error];
	expect(error).to.beNil();
	expect(builder).notTo.beNil();
});

it(@"should be possible to add an entry to a builder", ^{
	NSError *error = nil;
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
	expect(builder).notTo.beNil();
	expect(error).to.beNil();	
	
	GTTreeEntry *entry = [builder addEntryWithSha1:testTreeSHA filename:@"tree" filemode:GIT_FILEMODE_TREE error:&error];
	expect(entry).notTo.beNil();
	expect(error).to.beNil();
	
	NSUInteger numberOfEntries = [builder entryCount];
	expect(numberOfEntries).to.beGreaterThan(0);
});

it(@"should be possible to remove an entry from a builder", ^{
	NSError *error = nil;
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
	expect(builder).notTo.beNil();
	expect(error).to.beNil();
	
	NSString *filename = @"tree";
	GTTreeEntry *entry = [builder addEntryWithSha1:testTreeSHA filename:filename filemode:GIT_FILEMODE_TREE error:&error];
	expect(entry).notTo.beNil();
	expect(error).to.beNil();
	
	NSUInteger numberOfEntries = [builder entryCount];
	expect(numberOfEntries).to.beGreaterThan(0);
	
	BOOL success = [builder removeEntryWithFilename:filename error:&error];
	expect(success).to.beTruthy();
	expect(error).to.beNil();
	
	numberOfEntries = [builder entryCount];
	expect(numberOfEntries).to.beLessThan(1);
	
});

it(@"should be possible to filter a builder", ^{
	NSError *error = nil;
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
	expect(builder).notTo.beNil();
	expect(error).to.beNil();

	GTRepository *repo = [self fixtureRepositoryNamed:@"testrepo.git"];
	expect(repo).notTo.beNil();	
	
	GTBlob *blob = [GTBlob blobWithString:@"Hi, how are you?" inRepository:repo error:&error];
	expect(blob).notTo.beNil();
	expect(error).to.beNil();
	
	[builder addEntryWithSha1:blob.sha filename:@"hi.txt" filemode:GIT_FILEMODE_BLOB error:&error];
	
	NSUInteger numberOfEntries = [builder entryCount];
	expect(numberOfEntries).to.beGreaterThan(0);	
	
	[builder filter:filter_callback context:NULL];
	
	numberOfEntries = [builder entryCount];
	expect(numberOfEntries).to.beLessThan(1);
	
});

it(@"should be possible to find an entry by file name in a builder", ^{
	NSError *error = nil;
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
	expect(builder).notTo.beNil();
	expect(error).to.beNil();
	
	NSString *filename = @"tree";
	GTTreeEntry *entry = [builder addEntryWithSha1:testTreeSHA filename:filename filemode:GIT_FILEMODE_TREE error:&error];
	expect(entry).notTo.beNil();
	expect(error).to.beNil();
	
	GTTreeEntry *foundEntry = [builder entryWithName:filename];
	expect([foundEntry.sha isEqual:entry.sha]).to.beTruthy();
});

it(@"should be possible to write a builder to a repository", ^{
	NSError *error = nil;
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil error:&error];
	expect(builder).notTo.beNil();
	expect(error).to.beNil();
	
	GTRepository *repo = [self fixtureRepositoryNamed:@"testrepo.git"];
	expect(repo).notTo.beNil();
	
	GTBlob *blob = [GTBlob blobWithString:@"Hi, how are you?" inRepository:repo error:&error];
	expect(blob).notTo.beNil();
	expect(error).to.beNil();
	
	[builder addEntryWithSha1:blob.sha filename:@"hi.txt" filemode:GIT_FILEMODE_BLOB error:&error];

	GTTree *writtenTree = [builder writeTreeToRepository:repo error:&error];
	expect(writtenTree).notTo.beNil();
	expect(error).to.beNil();
});

SpecEnd
