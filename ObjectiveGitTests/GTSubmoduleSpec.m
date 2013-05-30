//
//  GTSubmoduleSpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-05-29.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

SpecBegin(GTSubmodule)

__block GTRepository *repo;

beforeEach(^{
	repo = [self fixtureRepositoryNamed:@"repo-with-submodule"];
	expect(repo).notTo.beNil();
});

it(@"should enumerate top-level submodules", ^{
	NSMutableSet *names = [NSMutableSet set];
	[repo enumerateSubmodulesRecursively:NO usingBlock:^(GTSubmodule *submodule, BOOL *stop) {
		expect(stop).notTo.beNil();

		expect(submodule).to.beKindOf(GTSubmodule.class);
		expect(submodule.name).notTo.beNil();

		[names addObject:submodule.name];
	}];

	NSSet *expectedNames = [NSSet setWithArray:@[ @"Archimedes", @"Test_App", @"Test_App2" ]];
	expect(names).to.equal(expectedNames);
});

it(@"should enumerate submodules recursively", ^{
	NSMutableSet *names = [NSMutableSet set];
	[repo enumerateSubmodulesRecursively:YES usingBlock:^(GTSubmodule *submodule, BOOL *stop) {
		expect(stop).notTo.beNil();

		expect(submodule).to.beKindOf(GTSubmodule.class);
		expect(submodule.name).notTo.beNil();

		[names addObject:submodule.name];
	}];

	NSSet *expectedNames = [NSSet setWithArray:@[ @"Archimedes", @"Configuration", @"ArchimedesTests/expecta", @"ArchimedesTests/specta", @"Test_App", @"Test_App2" ]];
	expect(names).to.equal(expectedNames);
});

it(@"should terminate enumeration early", ^{
	__block NSUInteger count = 0;
	[repo enumerateSubmodulesRecursively:NO usingBlock:^(GTSubmodule *submodule, BOOL *stop) {
		if (count == 2) {
			*stop = YES;
		} else {
			count++;
		}
	}];

	expect(count).to.equal(2);
});

describe(@"clean, checked out submodule", ^{
	__block GTSubmodule *submodule;

	beforeEach(^{
		NSError *error = nil;
		submodule = [repo submoduleWithName:@"Test_App" error:&error];
		expect(submodule).notTo.beNil();
		expect(error).to.beNil();

		expect(submodule.name).to.equal(@"Test_App");
		expect(submodule.repository).to.beIdenticalTo(repo);
		expect(submodule.git_submodule).notTo.beNil();
	});

	it(@"should have identical OIDs", ^{
		expect(submodule.HEADOID.SHA).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
		expect(submodule.indexOID.SHA).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
		expect(submodule.workingDirectoryOID.SHA).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
	});

	it(@"should have a clean status", ^{
		GTSubmoduleStatus expectedStatus = GTSubmoduleStatusExistsInHEAD | GTSubmoduleStatusExistsInIndex | GTSubmoduleStatusExistsInConfig | GTSubmoduleStatusExistsInWorkingDirectory;

		__block NSError *error = nil;
		expect([submodule statusWithError:&error]).to.equal(expectedStatus);
		expect(error).to.beNil();
	});

	it(@"should open a repository" ,^{
		NSError *error = nil;
		GTRepository *submoduleRepo = [submodule submoduleRepositoryWithError:&error];
		expect(submoduleRepo).notTo.beNil();
		expect(error).to.beNil();

		expect(submoduleRepo.fileURL).to.equal([repo.fileURL URLByAppendingPathComponent:@"Test_App"]);
		expect(submoduleRepo.bare).to.beFalsy();
		expect(submoduleRepo.empty).to.beFalsy();
		expect(submoduleRepo.headDetached).to.beTruthy();
		expect([submoduleRepo isWorkingDirectoryClean]).to.beTruthy();
	});
});

describe(@"dirty, checked out submodule", ^{
	__block GTSubmodule *submodule;

	beforeEach(^{
		NSError *error = nil;
		submodule = [repo submoduleWithName:@"Test_App2" error:&error];
		expect(submodule).notTo.beNil();
		expect(error).to.beNil();

		expect(submodule.name).to.equal(@"Test_App2");
		expect(submodule.repository).to.beIdenticalTo(repo);
		expect(submodule.git_submodule).notTo.beNil();
	});

	it(@"should have varying OIDs", ^{
		expect(submodule.HEADOID.SHA).to.equal(@"a4bca6b67a5483169963572ee3da563da33712f7");
		expect(submodule.indexOID.SHA).to.equal(@"93f5b550149f9f4c702c9de9a8b0a8a357f0c41c");
		expect(submodule.workingDirectoryOID.SHA).to.equal(@"1d69f3c0aeaf0d62e25591987b93b8ffc53abd77");
	});

	it(@"should have a dirty status", ^{
		GTSubmoduleStatus expectedStatus =
			GTSubmoduleStatusExistsInHEAD | GTSubmoduleStatusExistsInIndex | GTSubmoduleStatusExistsInConfig | GTSubmoduleStatusExistsInWorkingDirectory |
			GTSubmoduleStatusModifiedInIndex | GTSubmoduleStatusModifiedInWorkingDirectory |
			GTSubmoduleStatusDirtyIndex | GTSubmoduleStatusDirtyWorkingDirectory | GTSubmoduleStatusUntrackedFilesInWorkingDirectory;

		__block NSError *error = nil;
		expect([submodule statusWithError:&error]).to.equal(expectedStatus);
		expect(error).to.beNil();
	});

	it(@"should open a repository" ,^{
		NSError *error = nil;
		GTRepository *submoduleRepo = [submodule submoduleRepositoryWithError:&error];
		expect(submoduleRepo).notTo.beNil();
		expect(error).to.beNil();

		expect(submoduleRepo.fileURL).to.equal([repo.fileURL URLByAppendingPathComponent:@"Test_App2"]);
		expect(submoduleRepo.bare).to.beFalsy();
		expect(submoduleRepo.empty).to.beFalsy();
		expect(submoduleRepo.headDetached).to.beTruthy();
		expect([submoduleRepo isWorkingDirectoryClean]).to.beFalsy();
	});
});

SpecEnd
