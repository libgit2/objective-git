//
//  GTNoteSpec.m
//  ObjectiveGitFramework
//
//  Created by Slava Karpenko on 2016/05/17.
//  Copyright (c) 2016 Wildbit LLC. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTNoteSpec)

__block GTRepository *repository;
__block GTCommit *initialCommit;

beforeEach(^{
	NSURL *fileURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:[[NSUUID alloc] init].UUIDString isDirectory:NO];
	repository = [GTRepository initializeEmptyRepositoryAtFileURL:fileURL options:nil error:NULL];
	expect(repository).notTo(beNil());
	
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil repository:repository error:NULL];
	expect(builder).notTo(beNil());
	
	GTTreeEntry *entry = [builder addEntryWithData:[@"Xyzzy" dataUsingEncoding:NSUTF8StringEncoding] fileName:@"test.txt" fileMode:GTFileModeBlob error:NULL];
	expect(entry).notTo(beNil());
	
	GTTree *tree = [builder writeTree:NULL];
	expect(tree).notTo(beNil());
	
	initialCommit = [repository createCommitWithTree:tree message:@"Initial commit" parents:nil updatingReferenceNamed:@"refs/heads/master" error:NULL];
	expect(initialCommit).notTo(beNil());
});

it(@"can create notes", ^{
	// Annotate the commit
	GTSignature *sig = [repository userSignatureForNow];
	expect(sig).notTo(beNil());
	
	NSError *err = nil;
	
	GTNote *note = [repository createNote:@"Note text" target:initialCommit referenceName:nil author:sig committer:sig overwriteIfExists:YES error:&err];
	expect(note).notTo(beNil());
	expect(err).to(beNil());
	
	[repository enumerateNotesWithReferenceName:nil error:&err usingBlock:^(GTNote *note, GTObject *object, NSError *error, BOOL *stop) {
		expect(error).to(beNil());
		expect(note).notTo(beNil());
		expect(object).notTo(beNil());
		
		expect(note.note).to(equal(@"Note text"));
	}];
	expect(err).to(beNil());
});

it(@"can delete notes", ^{
	// Annotate the commit
	GTSignature *sig = [repository userSignatureForNow];
	expect(sig).notTo(beNil());
	
	NSError *err = nil;
	
	GTNote *note = [repository createNote:@"Note text" target:initialCommit referenceName:nil author:sig committer:sig overwriteIfExists:YES error:&err];
	expect(note).notTo(beNil());
	expect(err).to(beNil());
	
	BOOL res = [repository removeNoteFromObject:initialCommit referenceName:nil author:sig committer:sig error:&err];
	expect(@(res)).to(beTrue());
	expect(err).to(beNil());
	
	NSMutableArray *notes = [NSMutableArray arrayWithCapacity:0];
	
	[repository enumerateNotesWithReferenceName:nil error:&err usingBlock:^(GTNote *note, GTObject *object, NSError *error, BOOL *stop) {
		[notes addObject:note];
	}];
	
	expect(@(notes.count)).to(equal(@(0)));
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
