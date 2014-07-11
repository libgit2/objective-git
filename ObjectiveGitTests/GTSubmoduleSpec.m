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
	repo = self.submoduleFixtureRepository;
	expect(repo).notTo.beNil();
});

it(@"should enumerate top-level submodules", ^{
	NSMutableSet *names = [NSMutableSet set];
	[repo enumerateSubmodulesRecursively:NO usingBlock:^(GTSubmodule *submodule, NSError *error, BOOL *stop) {
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
	[repo enumerateSubmodulesRecursively:YES usingBlock:^(GTSubmodule *submodule, NSError *error, BOOL *stop) {
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
	[repo enumerateSubmodulesRecursively:NO usingBlock:^(GTSubmodule *submodule, NSError *error, BOOL *stop) {
		if (count == 2) {
			*stop = YES;
		} else {
			count++;
		}
	}];

	expect(count).to.equal(2);
});

it(@"should write to the parent .git/config", ^{
	NSString *testURLString = @"fake_url";

	GTSubmodule *submodule = [repo submoduleWithName:@"Test_App" error:NULL];
	expect(submodule).notTo.beNil();
	expect(@(git_submodule_url(submodule.git_submodule))).notTo.equal(testURLString);

	git_submodule_set_url(submodule.git_submodule, testURLString.UTF8String);
	git_submodule_save(submodule.git_submodule);

	__block NSError *error = nil;
	expect([submodule writeToParentConfigurationDestructively:YES error:&error]).to.beTruthy();
	expect(error).to.beNil();

	submodule = [repo submoduleWithName:@"Test_App" error:NULL];
	expect(submodule).notTo.beNil();
	expect(@(git_submodule_url(submodule.git_submodule))).to.equal(testURLString);
});

it(@"should reload all submodules", ^{
	GTSubmodule *submodule = [repo submoduleWithName:@"new_submodule" error:NULL];
	expect(submodule).to.beNil();

	NSURL *gitmodulesURL = [repo.fileURL URLByAppendingPathComponent:@".gitmodules"];
	NSMutableString *gitmodules = [NSMutableString stringWithContentsOfURL:gitmodulesURL usedEncoding:NULL error:NULL];
	expect(gitmodules).notTo.beNil();

	[gitmodules appendString:@"[submodule \"new_submodule\"]\n\turl = some_url\n\tpath = new_submodule_path"];
	expect([gitmodules writeToURL:gitmodulesURL atomically:YES encoding:NSUTF8StringEncoding error:NULL]).to.beTruthy();

	__block NSError *error = nil;
	expect([repo reloadSubmodules:&error]).to.beTruthy();
	expect(error).to.beNil();

	submodule = [repo submoduleWithName:@"new_submodule" error:NULL];
	expect(submodule).notTo.beNil();
	expect(submodule.path).to.equal(@"new_submodule_path");
});

it(@"should add its HEAD to its parent's index", ^{
	GTSubmodule *submodule = [repo submoduleWithName:@"Test_App" error:NULL];
	expect(submodule).notTo.beNil();

	GTRepository *submoduleRepository = [[GTRepository alloc] initWithURL:[repo.fileURL URLByAppendingPathComponent:submodule.path] error:NULL];
	expect(submoduleRepository).notTo.beNil();

	GTCommit *commit = [submoduleRepository lookUpObjectByRevParse:@"HEAD^" error:NULL];
	BOOL success = [submoduleRepository checkoutCommit:commit strategy:GTCheckoutStrategyForce error:NULL progressBlock:nil];
	expect(success).to.beTruthy();

	success = [submodule addToIndex:NULL];
	expect(success).to.beTruthy();
});

describe(@"clean, checked out submodule", ^{
	__block GTSubmodule *submodule;

	beforeEach(^{
		NSError *error = nil;
		submodule = [repo submoduleWithName:@"Test_App" error:&error];
		expect(submodule).notTo.beNil();
		expect(error).to.beNil();

		expect(submodule.name).to.equal(@"Test_App");
		expect(submodule.path).to.equal(@"Test_App");
		expect(submodule.URLString).to.equal(@"../Test_App");
		expect(submodule.parentRepository).to.beIdenticalTo(repo);
		expect(submodule.git_submodule).notTo.beNil();
	});

	it(@"should compare equal to the same submodule", ^{
		expect(submodule).to.equal([repo submoduleWithName:@"Test_App" error:NULL]);
	});

	it(@"should compare unequal to a different submodule", ^{
		expect(submodule).notTo.equal([repo submoduleWithName:@"Test_App2" error:NULL]);
	});

	it(@"should have identical OIDs", ^{
		expect(submodule.HEADOID.SHA).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
		expect(submodule.indexOID.SHA).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
		expect(submodule.workingDirectoryOID.SHA).to.equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0");
	});

	it(@"should have a clean status", ^{
		GTSubmoduleStatus expectedStatus = GTSubmoduleStatusExistsInHEAD | GTSubmoduleStatusExistsInIndex | GTSubmoduleStatusExistsInConfig | GTSubmoduleStatusExistsInWorkingDirectory;

		__block NSError *error = nil;
		expect([submodule status:&error]).to.equal(expectedStatus);
		expect(error).to.beNil();
	});

	it(@"should open a repository" ,^{
		NSError *error = nil;
		GTRepository *submoduleRepo = [submodule submoduleRepository:&error];
		expect(submoduleRepo).notTo.beNil();
		expect(error).to.beNil();

		expect(submoduleRepo.fileURL).to.equal([repo.fileURL URLByAppendingPathComponent:@"Test_App"]);
		expect(submoduleRepo.bare).to.beFalsy();
		expect(submoduleRepo.empty).to.beFalsy();
		expect(submoduleRepo.HEADDetached).to.beTruthy();
		expect([submoduleRepo isWorkingDirectoryClean]).to.beTruthy();
	});

	it(@"should reload", ^{
		GTRepository *submoduleRepo = [submodule submoduleRepository:NULL];
		expect(submoduleRepo).notTo.beNil();

		GTCommit *newHEAD = (id)[submoduleRepo lookUpObjectBySHA:@"82dc47f6ba3beecab33080a1136d8913098e1801" objectType:GTObjectTypeCommit error:NULL];
		expect(newHEAD).notTo.beNil();
		expect([submoduleRepo resetToCommit:newHEAD resetType:GTRepositoryResetTypeHard error:NULL]).to.beTruthy();

		expect(submodule.workingDirectoryOID.SHA).notTo.equal(newHEAD.SHA);

		__block NSError *error = nil;
		expect([submodule reload:&error]).to.beTruthy();
		expect(error).to.beNil();

		expect(submodule.workingDirectoryOID.SHA).to.equal(newHEAD.SHA);
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
		expect(submodule.path).to.equal(@"Test_App2");
		expect(submodule.URLString).to.equal(@"../Test_App");
		expect(submodule.parentRepository).to.beIdenticalTo(repo);
		expect(submodule.git_submodule).notTo.beNil();
	});

	it(@"should compare equal to the same submodule", ^{
		expect(submodule).to.equal([repo submoduleWithName:@"Test_App2" error:NULL]);
	});

	it(@"should compare unequal to a different submodule", ^{
		expect(submodule).notTo.equal([repo submoduleWithName:@"Test_App" error:NULL]);
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
		expect([submodule status:&error]).to.equal(expectedStatus);
		expect(error).to.beNil();
	});

	it(@"should honor the ignore rule", ^{
		submodule.ignoreRule = GTSubmoduleIgnoreDirty;

		GTSubmoduleStatus expectedStatus =
			GTSubmoduleStatusExistsInHEAD | GTSubmoduleStatusExistsInIndex | GTSubmoduleStatusExistsInConfig | GTSubmoduleStatusExistsInWorkingDirectory |
			GTSubmoduleStatusModifiedInIndex | GTSubmoduleStatusModifiedInWorkingDirectory;

		expect([submodule status:NULL]).to.equal(expectedStatus);
	});

	it(@"should open a repository" ,^{
		NSError *error = nil;
		GTRepository *submoduleRepo = [submodule submoduleRepository:&error];
		expect(submoduleRepo).notTo.beNil();
		expect(error).to.beNil();

		expect(submoduleRepo.fileURL).to.equal([repo.fileURL URLByAppendingPathComponent:@"Test_App2"]);
		expect(submoduleRepo.bare).to.beFalsy();
		expect(submoduleRepo.empty).to.beFalsy();
		expect(submoduleRepo.HEADDetached).to.beTruthy();
		expect([submoduleRepo isWorkingDirectoryClean]).to.beFalsy();
	});

	it(@"should synchronize the remote URL", ^{
		GTConfiguration *config = [repo configurationWithError:NULL];
		expect(config).notTo.beNil();

		NSString *configKey = @"submodule.Test_App2.url";
		NSString *newOrigin = @"https://github.com/libgit2/objective-git.git";
		[config setString:newOrigin forKey:configKey];

		expect([config refresh:NULL]).to.beTruthy();
		expect([config stringForKey:configKey]).to.equal(newOrigin);

		__block NSError *error = nil;
		expect([submodule sync:&error]).to.beTruthy();

		expect([config refresh:NULL]).to.beTruthy();
		expect([config stringForKey:configKey]).to.equal(@"../Test_App");
	});
});

afterEach(^{
	[self tearDown];
});

SpecEnd
