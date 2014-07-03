//
//  GTReflogSpec.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 4/9/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTReflog.h"

SpecBegin(GTReflog)

__block GTReflog *reflog;
__block GTRepository *repository;
beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo.beNil();

	GTBranch *branch = [repository currentBranchWithError:NULL];
	expect(branch).notTo.beNil();
	
	reflog = branch.reference.reflog;
	expect(reflog).notTo.beNil();
});

describe(@"reading", ^{
	it(@"should be able to read reflog entries", ^{
		GTReflogEntry *entry = [reflog entryAtIndex:0];
		expect(entry).notTo.beNil();
		expect(entry.message).to.equal(@"commit: Add 2 text and 1 binary file for diff tests.");
		expect(entry.previousOID).to.equal([[GTOID alloc] initWithSHA:@"6b0c1c8b8816416089c534e474f4c692a76ac14f"]);
		expect(entry.updatedOID).to.equal([[GTOID alloc] initWithSHA:@"a4bca6b67a5483169963572ee3da563da33712f7"]);
		expect(entry.committer.name).to.equal(@"Danny Greg");
		expect(entry.committer.email).to.equal(@"danny@github.com");
	});
});

describe(@"writing", ^{
	it(@"should be able to write a new reflog entry", ^{
		static NSString * const message = @"Refloggin' ain't easy.";
		GTSignature *user = repository.userSignatureForNow;
		BOOL success = [reflog writeEntryWithCommitter:user message:message error:NULL];
		expect(success).to.beTruthy();

		GTReflogEntry *entry = [reflog entryAtIndex:0];
		expect(entry).notTo.beNil();
		expect(entry.message).to.equal(message);
		expect(entry.previousOID).to.equal([[GTOID alloc] initWithSHA:@"a4bca6b67a5483169963572ee3da563da33712f7"]);
		expect(entry.updatedOID).to.equal([[GTOID alloc] initWithSHA:@"a4bca6b67a5483169963572ee3da563da33712f7"]);
		expect(entry.committer.name).to.equal(user.name);
		expect(entry.committer.email).to.equal(user.email);
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
