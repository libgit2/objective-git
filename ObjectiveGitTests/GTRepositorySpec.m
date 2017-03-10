//
//  GTRepositorySpec.m
//  ObjectiveGitFramework
//
//  Created by Justin Spahr-Summers on 2013-04-29.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Nimble/Nimble.h>
#import <ObjectiveGit/ObjectiveGit.h>
#import <Quick/Quick.h>

#import "QuickSpec+GTFixtures.h"

QuickSpecBegin(GTRepositorySpec)

static NSString * const readmeFile = @"README.md";
static NSString * const readme1File = @"README1.txt";


__block GTRepository *repository;

beforeEach(^{
	repository = self.testAppFixtureRepository;
	expect(repository).notTo(beNil());
});

describe(@"+initializeEmptyRepositoryAtFileURL:bare:error:", ^{
	it(@"should initialize a repository with a working directory by default", ^{
		NSURL *newRepoURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"init-repo"];

		NSError *error;
		GTRepository *repository = [GTRepository initializeEmptyRepositoryAtFileURL:newRepoURL options:nil error:&error];
		expect(repository).notTo(beNil());
		expect(error).to(beNil());
		
		expect(repository.gitDirectoryURL).notTo(beNil());
		expect(@(repository.bare)).to(beFalsy());
	});

	it(@"should initialize a bare repository", ^{
		NSURL *newRepoURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"init-repo.git"];
		NSDictionary *options = @{
			GTRepositoryInitOptionsFlags: @(GTRepositoryInitBare | GTRepositoryInitCreatingRepositoryDirectory)
		};

		NSError *error;
		GTRepository *repository = [GTRepository initializeEmptyRepositoryAtFileURL:newRepoURL options:options error:&error];
		expect(repository).notTo(beNil());
		expect(error).to(beNil());
		
		expect(repository.gitDirectoryURL).notTo(beNil());
		expect(@(repository.bare)).to(beTruthy());
	});
});

describe(@"+repositoryWithURL:error:", ^{
	it(@"should fail to initialize non-existent repos", ^{
		NSError *error = nil;
		GTRepository *badRepo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:@"fake/1235"] error:&error];
		expect(badRepo).to(beNil());
		expect(error).notTo(beNil());
		expect(error.domain).to(equal(GTGitErrorDomain));
		expect(@(error.code)).to(equal(@(GIT_ENOTFOUND)));
	});
});

describe(@"+cloneFromURL:toWorkingDirectory:options:error:transferProgressBlock:checkoutProgressBlock:", ^{
	__block BOOL transferProgressCalled = NO;
	__block BOOL checkoutProgressCalled = NO;
	__block void (^transferProgressBlock)(const git_transfer_progress *, BOOL *);
	__block void (^checkoutProgressBlock)(NSString *, NSUInteger, NSUInteger);
	__block NSURL *originURL;
	__block NSURL *workdirURL;

	// TODO: Make real remote tests using a repo somewhere

	beforeEach(^{
		transferProgressCalled = NO;
		checkoutProgressCalled = NO;
		transferProgressBlock = ^(const git_transfer_progress *progress, BOOL *stop) {
            transferProgressCalled = YES;
        };
		checkoutProgressBlock = ^(NSString *path, NSUInteger completedSteps, NSUInteger totalSteps) {
            checkoutProgressCalled = YES;
        };

		workdirURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"temp-repo"];
	});

	describe(@"with local repositories", ^{
		beforeEach(^{
			originURL = self.bareFixtureRepository.gitDirectoryURL;
		});

		it(@"should handle normal clones", ^{
			NSError *error = nil;
			GTCheckoutOptions *checkoutOptions = [GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategySafe];
			checkoutOptions.progressBlock = checkoutProgressBlock;

			NSDictionary *cloneOptions = @{
										   GTRepositoryCloneOptionsCloneLocal: @YES,
										   GTRepositoryCloneOptionsCheckoutOptions: checkoutOptions,
										   };
			repository = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:cloneOptions error:&error transferProgressBlock:transferProgressBlock];
			expect(repository).notTo(beNil());
			expect(error).to(beNil());
			expect(@(transferProgressCalled)).to(beTruthy());
			expect(@(checkoutProgressCalled)).to(beTruthy());

			expect(@(repository.isBare)).to(beFalsy());

			GTReference *head = [repository headReferenceWithError:&error];
			expect(head).notTo(beNil());
			expect(error).to(beNil());
			expect(head.targetOID.SHA).to(equal(@"36060c58702ed4c2a40832c51758d5344201d89a"));
			expect(@(head.referenceType)).to(equal(@(GTReferenceTypeOid)));
		});

		it(@"should handle bare clones", ^{
			NSError *error = nil;
			GTCheckoutOptions *checkoutOptions = [GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategySafe];
			checkoutOptions.progressBlock = checkoutProgressBlock;

			NSDictionary *options = @{
									  GTRepositoryCloneOptionsBare: @YES,
									  GTRepositoryCloneOptionsCloneLocal: @YES,
									  GTRepositoryCloneOptionsCheckoutOptions: checkoutOptions,
									  };
			repository = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:options error:&error transferProgressBlock:transferProgressBlock];
			expect(repository).notTo(beNil());
			expect(error).to(beNil());
			expect(@(transferProgressCalled)).to(beTruthy());
			expect(@(checkoutProgressCalled)).to(beFalsy());

			expect(@(repository.isBare)).to(beTruthy());

			GTReference *head = [repository headReferenceWithError:&error];
			expect(head).notTo(beNil());
			expect(error).to(beNil());
			expect(head.targetOID.SHA).to(equal(@"36060c58702ed4c2a40832c51758d5344201d89a"));
			expect(@(head.referenceType)).to(equal(@(GTReferenceTypeOid)));
		});

		it(@"should have set a valid remote URL", ^{
			NSError *error = nil;
			GTCheckoutOptions *checkoutOptions = [GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategySafe];
			checkoutOptions.progressBlock = checkoutProgressBlock;

			repository = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:@{ GTRepositoryCloneOptionsCheckoutOptions: checkoutOptions } error:&error transferProgressBlock:transferProgressBlock];
			expect(repository).notTo(beNil());
			expect(error).to(beNil());

			GTRemote *originRemote = [GTRemote remoteWithName:@"origin" inRepository:repository error:&error];
			expect(error).to(beNil());
			expect(originRemote.URLString).to(equal(originURL.path));
		});
	});

	describe(@"with remote repositories", ^{
		__block GTCredentialProvider *provider = nil;
		NSString *userName = [[NSProcessInfo processInfo] environment][@"GTUserName"];
		NSString *publicKeyPath = [[[NSProcessInfo processInfo] environment][@"GTPublicKey"] stringByStandardizingPath];
		NSString *privateKeyPath = [[[NSProcessInfo processInfo] environment][@"GTPrivateKey"] stringByStandardizingPath];
		NSString *privateKeyPassword = [[NSProcessInfo processInfo] environment][@"GTPrivateKeyPassword"];

		beforeEach(^{
			// Let's clone libgit2's documentation
			originURL = [NSURL URLWithString:@"git@github.com:libgit2/libgit2.github.com.git"];
		});

		if (userName && publicKeyPath && privateKeyPath && privateKeyPassword) {
			it(@"should handle clones", ^{
				__block NSError *error = nil;

				provider = [GTCredentialProvider providerWithBlock:^GTCredential *(GTCredentialType type, NSString *URL, NSString *credUserName) {
					expect(URL).to(equal(originURL.absoluteString));
					expect(@(type & GTCredentialTypeSSHKey)).to(beTruthy());
					GTCredential *cred = nil;
					// cred = [GTCredential credentialWithUserName:userName password:password error:&error];
					cred = [GTCredential credentialWithUserName:credUserName publicKeyURL:[NSURL fileURLWithPath:publicKeyPath] privateKeyURL:[NSURL fileURLWithPath:privateKeyPath] passphrase:privateKeyPassword error:&error];
					expect(cred).notTo(beNil());
					expect(error).to(beNil());
					return cred;
				}];

				GTCheckoutOptions *checkoutOptions = [GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategySafe];
				checkoutOptions.progressBlock = checkoutProgressBlock;
				NSDictionary *cloneOptions = @{
											   GTRepositoryCloneOptionsCredentialProvider: provider,
											   GTRepositoryCloneOptionsCheckoutOptions: checkoutOptions,
											   };

				repository = [GTRepository cloneFromURL:originURL toWorkingDirectory:workdirURL options:cloneOptions error:&error transferProgressBlock:transferProgressBlock];
				expect(repository).notTo(beNil());
				expect(error).to(beNil());
				expect(@(transferProgressCalled)).to(beTruthy());
				expect(@(checkoutProgressCalled)).to(beTruthy());

				GTRemote *originRemote = [GTRemote remoteWithName:@"origin" inRepository:repository error:&error];
				expect(error).to(beNil());
				expect(originRemote.URLString).to(equal(originURL.absoluteString));
			});
		}
	});
});

describe(@"-headReferenceWithError:", ^{
	it(@"should allow HEAD to be looked up", ^{
		NSError *error = nil;
		GTReference *head = [self.bareFixtureRepository headReferenceWithError:&error];
		expect(head).notTo(beNil());
		expect(error).to(beNil());
		expect(head.targetOID.SHA).to(equal(@"36060c58702ed4c2a40832c51758d5344201d89a"));
		expect(@(head.referenceType)).to(equal(@(GTReferenceTypeOid)));
	});

	it(@"should fail to return HEAD for an unborn repo", ^{
		GTRepository *repo = self.blankFixtureRepository;
		expect(@(repo.isHEADUnborn)).to(beTruthy());

		NSError *error = nil;
		GTReference *head = [repo headReferenceWithError:&error];
		expect(head).to(beNil());
		expect(error).notTo(beNil());
		expect(error.domain).to(equal(GTGitErrorDomain));
        expect(@(error.code)).to(equal(@(GIT_EUNBORNBRANCH)));
	});
});

describe(@"-isEmpty", ^{
	it(@"should return NO for a non-empty repository", ^{
		expect(@(repository.isEmpty)).to(beFalsy());
	});

	it(@"should return YES for a new repository", ^{
		NSError *error = nil;
		NSURL *fileURL = [self.tempDirectoryFileURL URLByAppendingPathComponent:@"newrepo"];
		GTRepository *newRepo = [GTRepository initializeEmptyRepositoryAtFileURL:fileURL options:nil error:&error];
		expect(newRepo).notTo(beNil());
		expect(@(newRepo.isEmpty)).to(beTruthy());
		[NSFileManager.defaultManager removeItemAtURL:fileURL error:NULL];
	});
});

describe(@"-preparedMessage", ^{
	it(@"should return nil by default", ^{
		__block NSError *error = nil;
		expect([repository preparedMessageWithError:&error]).to(beNil());
		expect(error).to(beNil());
	});

	it(@"should return the contents of MERGE_MSG", ^{
		NSString *message = @"Commit summary\n\ndescription";
		expect(@([message writeToURL:[repository.gitDirectoryURL URLByAppendingPathComponent:@"MERGE_MSG"] atomically:YES encoding:NSUTF8StringEncoding error:NULL])).to(beTruthy());

		__block NSError *error = nil;
		expect([repository preparedMessageWithError:&error]).to(equal(message));
		expect(error).to(beNil());
	});
});

describe(@"-mergeBaseBetweenFirstOID:secondOID:error:", ^{
	it(@"should find the merge base between two branches", ^{
		NSError *error = nil;
		GTBranch *masterBranch = [repository lookUpBranchWithName:@"master" type:GTBranchTypeLocal success:NULL error:&error];
		expect(masterBranch).notTo(beNil());
		expect(error).to(beNil());

		GTBranch *otherBranch = [repository lookUpBranchWithName:@"other-branch" type:GTBranchTypeLocal success:NULL error:&error];
		expect(otherBranch).notTo(beNil());
		expect(error).to(beNil());

		GTCommit *mergeBase = [repository mergeBaseBetweenFirstOID:masterBranch.reference.OID secondOID:otherBranch.reference.OID error:&error];
		expect(mergeBase).notTo(beNil());
		expect(mergeBase.SHA).to(equal(@"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0"));
	});
});

describe(@"-allTagsWithError:", ^{
	it(@"should return all tags", ^{
		NSError *error = nil;
		NSArray *tags = [repository allTagsWithError:&error];
		expect(tags).notTo(beNil());
		expect(@(tags.count)).to(equal(@0));
	});
});

describe(@"-currentBranchWithError:", ^{
	it(@"should return the current branch", ^{
		NSError *error = nil;
		GTBranch *currentBranch = [repository currentBranchWithError:&error];
		expect(currentBranch).notTo(beNil());
		expect(error).to(beNil());
		expect(currentBranch.name).to(equal(@"refs/heads/master"));
	});
});

describe(@"-createBranchNamed:fromOID:committer:message:error:", ^{
	it(@"should create a local branch from the given OID", ^{
		GTBranch *currentBranch = [repository currentBranchWithError:NULL];
		expect(currentBranch).notTo(beNil());

		NSString *branchName = @"new-test-branch";

		NSError *error = nil;
		GTBranch *newBranch = [repository createBranchNamed:branchName fromOID:currentBranch.OID message:nil error:&error];
		expect(newBranch).notTo(beNil());
		expect(error).to(beNil());

		expect(newBranch.shortName).to(equal(branchName));
		expect(@(newBranch.branchType)).to(equal(@(GTBranchTypeLocal)));
		expect(newBranch.OID).to(equal(currentBranch.OID));
	});
});

describe(@"-localBranchesWithError:", ^{
	it(@"should return the local branches", ^{
		NSError *error = nil;
		NSArray *branches = [repository localBranchesWithError:&error];
		expect(branches).notTo(beNil());
		expect(error).to(beNil());
		expect(@(branches.count)).to(equal(@13));
	});
});

describe(@"-remoteBranchesWithError:", ^{
	it(@"should return remote branches", ^{
		NSError *error = nil;
		NSArray *branches = [repository remoteBranchesWithError:&error];
		expect(branches).notTo(beNil());
		expect(error).to(beNil());
		expect(@(branches.count)).to(equal(@1));
		GTBranch *remoteBranch = branches[0];
		expect(remoteBranch.name).to(equal(@"refs/remotes/origin/master"));
	});
});

describe(@"-referenceNamesWithError:", ^{
	it(@"should return reference names", ^{
		NSError *error = nil;
		NSArray *refs = [self.bareFixtureRepository referenceNamesWithError:&error];
		expect(refs).notTo(beNil());
		expect(error).to(beNil());

		expect(@(refs.count)).to(equal(@4));
		NSArray *expectedRefs = @[ @"refs/heads/master", @"refs/tags/v0.9", @"refs/tags/v1.0", @"refs/heads/packed" ];
		expect(refs).to(equal(expectedRefs));
	});
});

describe(@"-OIDByCreatingTagNamed:target:tagger:message:error", ^{
	it(@"should create a new tag",^{
		NSError *error = nil;
		NSString *SHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		GTRepository *repo = self.bareFixtureRepository;
		GTTag *tag = (GTTag *)[repo lookUpObjectBySHA:SHA error:&error];

		GTOID *newOID = [repo OIDByCreatingTagNamed:@"a_new_tag" target:tag.target tagger:tag.tagger message:@"my tag\n" error:&error];
		expect(newOID).notTo(beNil());

		tag = (GTTag *)[repo lookUpObjectByOID:newOID error:&error];
		expect(error).to(beNil());
		expect(tag).notTo(beNil());
		expect(newOID.SHA).to(equal(tag.SHA));
		expect(tag.type).to(equal(@"tag"));
		expect(tag.message).to(equal(@"my tag\n"));
		expect(tag.name).to(equal(@"a_new_tag"));
		expect(tag.target.SHA).to(equal(@"5b5b025afb0b4c913b4c338a42934a3863bf3644"));
		expect(@(tag.targetType)).to(equal(@(GTObjectTypeCommit)));
	});

	it(@"should fail to create an already existing tag", ^{
		NSError *error = nil;
		NSString *SHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		GTRepository *repo = self.bareFixtureRepository;
		GTTag *tag = (GTTag *)[repo lookUpObjectBySHA:SHA error:&error];

		GTOID *OID = [repo OIDByCreatingTagNamed:tag.name target:tag.target tagger:tag.tagger message:@"new message" error:&error];
		expect(OID).to(beNil());
		expect(error).notTo(beNil());
	});
});

describe(@"move head", ^{
	beforeEach(^{
		repository = self.testAppFixtureRepository;
	});

	//- (BOOL)moveHEADToReference:(GTReference *)reference error:(NSError **)error;
	it(@"should move to reference", ^{
		NSError *error = nil;
		GTReference *originalHead = [repository headReferenceWithError:NULL];

		GTReference *targetReference = [repository lookUpReferenceWithName:@"refs/heads/other-branch" error:NULL];
		expect(targetReference).notTo(beNil());

		// -> Test the move
		BOOL success = [repository moveHEADToReference:targetReference error:&error];
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());

		// Verify
		GTReference *head = [repository headReferenceWithError:&error];
		expect(head).notTo(beNil());
		expect(head).notTo(equal(originalHead));
		expect(head.targetOID.SHA).to(equal(targetReference.targetOID.SHA));
	});

	//- (BOOL)moveHEADToCommit:(GTCommit *)commit error:(NSError **)error;
	it(@"should move to commit", ^{
		NSError *error = nil;
		GTReference *originalHead = [repository headReferenceWithError:NULL];
		NSString *targetCommitSHA = @"f7ecd8f4404d3a388efbff6711f1bdf28ffd16a0";

		GTCommit *commit = [repository lookUpObjectBySHA:targetCommitSHA error:NULL];
		expect(commit).notTo(beNil());

		GTCommit *originalHeadCommit = [repository lookUpObjectByOID:originalHead.targetOID error:NULL];
		expect(originalHeadCommit).notTo(beNil());

		// -> Test the move
		BOOL success = [repository moveHEADToCommit:commit error:&error];
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());

		// Test for detached?

		// Verify
		GTReference *head = [repository headReferenceWithError:&error];
		expect(head).notTo(beNil());
		expect(head.targetOID.SHA).to(equal(targetCommitSHA));
	});
});


describe(@"-checkout:strategy:error:progressBlock:", ^{
	it(@"should allow references", ^{
		NSError *error = nil;
		GTReference *ref = [repository lookUpReferenceWithName:@"refs/heads/other-branch" error:&error];
		expect(ref).notTo(beNil());
		expect(error.localizedDescription).to(beNil());
		BOOL result = [repository checkoutReference:ref options:[GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategyAllowConflicts] error:&error];
		expect(@(result)).to(beTruthy());
		expect(error.localizedDescription).to(beNil());
	});

	it(@"should allow commits", ^{
		NSError *error = nil;
		GTCommit *commit = [repository lookUpObjectBySHA:@"1d69f3c0aeaf0d62e25591987b93b8ffc53abd77" objectType:GTObjectTypeCommit error:&error];
		expect(commit).notTo(beNil());
		expect(error.localizedDescription).to(beNil());
		BOOL result = [repository checkoutCommit:commit options:[GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategyAllowConflicts] error:&error];
		expect(@(result)).to(beTruthy());
		expect(error.localizedDescription).to(beNil());
	});
});

describe(@"-checkout:strategy:notifyFlags:error:notifyBlock:progressBlock:", ^{
	it(@"should fail ref checkout with conflict and notify", ^{
		NSError *error = nil;
		GTReference *ref = [repository lookUpReferenceWithName:@"refs/heads/other-branch" error:&error];
		expect(ref).notTo(beNil());
		expect(error.localizedDescription).to(beNil());
		BOOL writeResult = [@"Conflicting data in README.md\n" writeToURL:[repository.fileURL URLByAppendingPathComponent:readmeFile] atomically:YES encoding:NSUTF8StringEncoding error:&error];
		expect(@(writeResult)).to(beTruthy());
		__block NSUInteger notifyCount = 0;
		__block BOOL readmeFileConflicted = NO;
		int (^notifyBlock)(GTCheckoutNotifyFlags, NSString *, GTDiffFile *, GTDiffFile *, GTDiffFile *);
		notifyBlock = ^(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir) {
			notifyCount++;
			if([path isEqualToString:readmeFile] && (why & GTCheckoutNotifyConflict)) {
				readmeFileConflicted = YES;
			}
			return 0;
		};

		GTCheckoutOptions *options = [GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategySafe notifyFlags:GTCheckoutNotifyConflict notifyBlock:notifyBlock];
		BOOL result = [repository checkoutReference:ref options:options error:&error];
		expect(@(notifyCount)).to(equal(@(1)));
		expect(@(readmeFileConflicted)).to(beTruthy());
		expect(@(result)).to(beFalsy());
		expect(@(error.code)).to(equal(@(GIT_ECONFLICT)));
	});

	it(@"should fail commit checkout with conflict and notify", ^{
		NSError *error = nil;
		GTCommit *commit = [repository lookUpObjectBySHA:@"1d69f3c0aeaf0d62e25591987b93b8ffc53abd77" objectType:GTObjectTypeCommit error:&error];
		expect(commit).notTo(beNil());
		expect(error.localizedDescription).to(beNil());
		BOOL writeResult = [@"Conflicting data in README1.txt\n" writeToURL:[repository.fileURL URLByAppendingPathComponent:readme1File] atomically:YES encoding:NSUTF8StringEncoding error:&error];
		expect(@(writeResult)).to(beTruthy());
		__block NSUInteger notifyCount = 0;
		__block BOOL readme1FileConflicted = NO;
		int (^notifyBlock)(GTCheckoutNotifyFlags, NSString *, GTDiffFile *, GTDiffFile *, GTDiffFile *);
		notifyBlock = ^(GTCheckoutNotifyFlags why, NSString *path, GTDiffFile *baseline, GTDiffFile *target, GTDiffFile *workdir) {
			notifyCount++;
			if([path isEqualToString:readme1File] && (why & GTCheckoutNotifyConflict)) {
				readme1FileConflicted = YES;
			}
			return 0;
		};


		GTCheckoutOptions *options = [GTCheckoutOptions checkoutOptionsWithStrategy:GTCheckoutStrategySafe notifyFlags:GTCheckoutNotifyConflict notifyBlock:notifyBlock];
		BOOL result = [repository checkoutCommit:commit options:options error:&error];
		expect(@(notifyCount)).to(equal(@(1)));
		expect(@(readme1FileConflicted)).to(beTruthy());
		expect(@(result)).to(beFalsy());
		expect(@(error.code)).to(equal(@(GIT_ECONFLICT)));
	});
});

describe(@"-remoteNamesWithError:", ^{
	it(@"allows access to remote names", ^{
		NSError *error = nil;
		NSArray *remoteNames = [repository remoteNamesWithError:&error];
		expect(error.localizedDescription).to(beNil());
		expect(remoteNames).notTo(beNil());
	});

	it(@"returns remote names if there are any", ^{
		NSError *error = nil;
		NSString *remoteName = @"testremote";
		GTRemote *remote = [GTRemote createRemoteWithName:remoteName URLString:@"git://user@example.com/testrepo" inRepository:repository error:&error];
		expect(error.localizedDescription).to(beNil());
		expect(remote).notTo(beNil());

		NSArray *remoteNames = [repository remoteNamesWithError:&error];
		expect(error.localizedDescription).to(beNil());
		expect(remoteNames).to(contain(remoteName));
	});
});

describe(@"-resetToCommit:withResetType:error:", ^{
	beforeEach(^{
		repository = self.bareFixtureRepository;
	});

	it(@"should move HEAD when used", ^{
		NSError *error = nil;
		GTReference *originalHead = [repository headReferenceWithError:NULL];
		NSString *resetTargetSHA = @"8496071c1b46c854b31185ea97743be6a8774479";

		GTCommit *commit = [repository lookUpObjectBySHA:resetTargetSHA error:NULL];
		expect(commit).notTo(beNil());
		GTCommit *originalHeadCommit = [repository lookUpObjectByOID:originalHead.targetOID error:NULL];
		expect(originalHeadCommit).notTo(beNil());

		BOOL success = [repository resetToCommit:commit resetType:GTRepositoryResetTypeSoft error:&error];
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());

		GTReference *head = [repository headReferenceWithError:&error];
		expect(head).notTo(beNil());
		expect(head.targetOID.SHA).to(equal(resetTargetSHA));

		success = [repository resetToCommit:originalHeadCommit resetType:GTRepositoryResetTypeSoft error:&error];
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());

		head = [repository headReferenceWithError:&error];
		expect(head.targetOID).to(equal(originalHead.targetOID));
	});
});

describe(@"-lookUpBranchWithName:type:error:", ^{
	it(@"should look up a local branch", ^{
		NSError *error = nil;
		BOOL success = NO;
		GTBranch *branch = [repository lookUpBranchWithName:@"master" type:GTBranchTypeLocal success:&success error:&error];

		expect(branch).notTo(beNil());
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());
	});

	it(@"should look up a remote branch", ^{
		NSError *error = nil;
		BOOL success = NO;
		GTBranch *branch = [repository lookUpBranchWithName:@"origin/master" type:GTBranchTypeRemote success:&success error:&error];

		expect(branch).notTo(beNil());
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());
	});

	it(@"should return nil for a nonexistent branch", ^{
		NSError *error = nil;
		BOOL success = NO;
		GTBranch *branch = [repository lookUpBranchWithName:@"foobar" type:GTBranchTypeLocal success:&success error:&error];

		expect(branch).to(beNil());
		expect(@(success)).to(beTruthy());
		expect(error).to(beNil());
	});
});

describe(@"-lookUpObjectByRevParse:error:", ^{
	void (^expectSHAForRevParse)(NSString *, NSString *) = ^(NSString *SHA, NSString *spec) {
		NSError *error = nil;
		GTObject *obj = [repository lookUpObjectByRevParse:spec error:&error];

		if (SHA != nil) {
			expect(error).to(beNil());
			expect(obj).notTo(beNil());
			expect(obj.SHA).to(equal(SHA));
		} else {
			expect(error).notTo(beNil());
			expect(obj).to(beNil());
		}
	};;

	beforeEach(^{
		repository = self.bareFixtureRepository;
	});

	it(@"should parse various revspecs", ^{
		expectSHAForRevParse(@"36060c58702ed4c2a40832c51758d5344201d89a", @"master");
		expectSHAForRevParse(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", @"master~");
		expectSHAForRevParse(@"8496071c1b46c854b31185ea97743be6a8774479", @"master@{2}");
		expectSHAForRevParse(nil, @"master^2");
		expectSHAForRevParse(nil, @"");
		expectSHAForRevParse(@"0c37a5391bbff43c37f0d0371823a5509eed5b1d", @"v1.0");
	});
});

describe(@"-branches:", ^{
	__block NSArray *branches;

	beforeEach(^{
		GTRepository *repository = [self testAppForkFixtureRepository];
		branches = [repository branches:NULL];
		expect(branches).notTo(beNil());
	});

	it(@"should combine a local branch with its remote branch", ^{
		NSMutableArray *localBranches = [NSMutableArray array];
		NSMutableArray *remoteBranches = [NSMutableArray array];
		for (GTBranch *branch in branches) {
			if ([branch.shortName isEqual:@"BranchA"]) {
				if (branch.branchType == GTBranchTypeLocal) {
					[localBranches addObject:branch];
				} else {
					[remoteBranches addObject:branch];
				}
			}
		}

		expect(@(localBranches.count)).to(equal(@1));

		GTBranch *localBranchA = localBranches[0];
		GTBranch *trackingBranch = [localBranchA trackingBranchWithError:NULL success:NULL];
		expect(trackingBranch.remoteName).to(equal(@"origin"));

		expect(@(remoteBranches.count)).to(equal(@1));

		GTBranch *remoteBranchA = remoteBranches[0];
		expect(remoteBranchA.remoteName).to(equal(@"github"));
	});

	it(@"should contain local branches", ^{
		NSInteger index = [branches indexOfObjectPassingTest:^(GTBranch *branch, NSUInteger idx, BOOL *stop) {
			return [branch.shortName isEqual:@"new-shite"];
		}];
		expect(@(index)).notTo(equal(@(NSNotFound)));
	});

	it(@"should contain remote branches which exist on multiple remotes", ^{
		NSUInteger matches = 0;
		for (GTBranch *branch in branches) {
			if ([branch.shortName isEqual:@"blah"] && branch.branchType == GTBranchTypeRemote) {
				matches++;
			}
		}
		expect(@(matches)).to(equal(@2));
	});
});

describe(@"-userSignatureForNow", ^{
	static NSString * const userName = @"johnsmith";
	static NSString * const email = @"johnsmith@gmail.com";

	__block GTConfiguration *configuration;

	beforeEach(^{
		configuration = [repository configurationWithError:NULL];
		expect(configuration).notTo(beNil());
	});

	it(@"should use the values from the config", ^{
		[configuration setString:userName forKey:@"user.name"];
		[configuration setString:email forKey:@"user.email"];

		GTSignature *signature = [repository userSignatureForNow];
		expect(signature.name).to(equal(userName));
		expect(signature.email).to(equal(email));
	});

	describe(@"invalid values", ^{
		it(@"should use a default value if the name is empty", ^{
			[configuration setString:@"" forKey:@"user.name"];
			[configuration setString:email forKey:@"user.email"];

			GTSignature *signature = [repository userSignatureForNow];
			expect(@(signature.name.length)).to(beGreaterThan(@0));
			expect(@(signature.email.length)).to(beGreaterThan(@0));
		});

		it(@"should use a default value if the email is empty", ^{
			[configuration setString:userName forKey:@"user.name"];
			[configuration setString:@"" forKey:@"user.email"];

			GTSignature *signature = [repository userSignatureForNow];
			expect(@(signature.name.length)).to(beGreaterThan(@0));
			expect(@(signature.email.length)).to(beGreaterThan(@0));
		});

		it(@"should use a default value if the email contains angled brackets", ^{
			[configuration setString:userName forKey:@"user.name"];
			[configuration setString:@"<johnsmith@gmail.com>" forKey:@"user.email"];

			GTSignature *signature = [repository userSignatureForNow];
			expect(@(signature.name.length)).to(beGreaterThan(@0));
			expect(@(signature.email.length)).to(beGreaterThan(@0));
		});
	});
});

describe(@"-calculateState:withError:", ^{
	it(@"should find if the repository is mid-merge", ^{
		GTRepository *repository = [self conflictedFixtureRepository];
		GTRepositoryStateType state;
		BOOL result;
		result = [repository calculateState:&state withError:NULL];
		expect(@(result)).to(beTruthy());
		expect(@(state)).to(equal(@(GTRepositoryStateMerge)));
	});
	
	it(@"should return none otherwise", ^{
		GTRepository *repository = [self testAppFixtureRepository];
		GTRepositoryStateType state;
		BOOL result;
		result = [repository calculateState:&state withError:NULL];
		expect(@(result)).to(beTruthy());
		expect(@(state)).to(equal(@(GTRepositoryStateNone)));
	});
});

describe(@"-cleanupStateWithError:", ^{
	it(@"should return a repository to a pre-merge state", ^{
		GTRepository *repository = [self conflictedFixtureRepository];
		
		GTRepositoryStateType state;
		BOOL result;
		result = [repository calculateState:&state withError:NULL];
		expect(@(result)).to(beTruthy());
		expect(@(state)).to(equal(@(GTRepositoryStateMerge)));
		
		expect(@([repository cleanupStateWithError:NULL])).to(beTruthy());
		
		result = [repository calculateState:&state withError:NULL];
		expect(@(result)).to(beTruthy());
		expect(@(state)).to(equal(@(GTRepositoryStateNone)));
	});
});

afterEach(^{
	[self tearDown];
});

QuickSpecEnd
