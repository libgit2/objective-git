//
//  GTRepositoryCommittingSpec.m
//  ObjectiveGitFramework
//
//  Created by Etienne Samson on 2013-07-10.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTRepositoryCommitting)

__block GTRepository *repository;

beforeEach(^{
	CFUUIDRef UUIDRef = CFUUIDCreate(NULL);
	NSString *UUID = CFBridgingRelease(CFUUIDCreateString(NULL, UUIDRef));
	CFRelease(UUIDRef);

	NSURL *fileURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:UUID isDirectory:NO];
	repository = [GTRepository initializeEmptyRepositoryAtFileURL:fileURL options:nil error:NULL];
	expect(repository).notTo(beNil());
});

it(@"can create commits", ^{
	GTTreeBuilder *builder = [[GTTreeBuilder alloc] initWithTree:nil repository:repository error:NULL];
	expect(builder).notTo(beNil());

	GTTreeEntry *entry = [builder addEntryWithData:[@"Another file contents" dataUsingEncoding:NSUTF8StringEncoding] fileName:@"Test file 2.txt" fileMode:GTFileModeBlob error:NULL];
	expect(entry).notTo(beNil());

	GTTree *subtree = [builder writeTree:NULL];
	expect(subtree).notTo(beNil());

	[builder clear];

	entry = [builder addEntryWithData:[@"Test contents" dataUsingEncoding:NSUTF8StringEncoding] fileName:@"Test file.txt" fileMode:GTFileModeBlob error:NULL];
	expect(entry).notTo(beNil());

	entry = [builder addEntryWithOID:subtree.OID fileName:@"subdir" fileMode:GTFileModeTree error:NULL];
	expect(entry).notTo(beNil());

	GTTree *tree = [builder writeTree:NULL];
	expect(tree).notTo(beNil());

	GTCommit *initialCommit = [repository createCommitWithTree:tree message:@"Initial commit" parents:nil updatingReferenceNamed:@"refs/heads/master" error:NULL];
	expect(initialCommit).notTo(beNil());

	GTReference *ref = [repository headReferenceWithError:NULL];
	expect(ref).notTo(beNil());
	expect(ref.resolvedTarget).to(equal(initialCommit));
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
