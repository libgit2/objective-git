//
//  GTOIDSpec.m
//  ObjectiveGitFramework
//
//  Created by Ezekiel Pierson on 2013-09-06.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTTag.h"

SpecBegin(GTTag)

__block GTTag *tag;
__block GTRepository *repository;

beforeEach(^{
	NSError *error = nil;
	repository = self.bareFixtureRepository;
	NSString *tagSHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	tag = [GTTag lookupWithSHA:tagSHA inRepository:repository error:&error];
	expect(error).to.beFalsy();
	expect(tag).to.beTruthy();
	expect(tagSHA).to.equal(tag.SHA);
});

it(@"can read tag data", ^{
	expect(tag.type).to.equal(@"tag");
	expect(tag.name).to.equal(@"v1.0");
	expect(tag.message).to.equal(@"test tag message\n");
	expect(tag.target.SHA).to.equal(@"5b5b025afb0b4c913b4c338a42934a3863bf3644");
	expect(GTObjectTypeCommit).to.equal(tag.targetType);
	
	GTSignature *signature = tag.tagger;
	expect(signature.name).to.equal(@"Scott Chacon");
	expect((int)[signature.time timeIntervalSince1970]).to.equal(1288114383);
	expect(signature.email).to.equal(@"schacon@gmail.com");
});


describe(@"+tagByCreatingTagNamed:target:message:tagger:force:inRepository:error:", ^{
	__block NSString *originalTagSHA = nil;
	__block GTTag *originalTag = nil;
	beforeEach(^{
		originalTagSHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		originalTag = [GTTag lookupWithSHA:originalTagSHA inRepository:repository error:NULL];
	});

	it(@"should create a new tag",^{
		NSError *error = nil;

		GTTag *tag = [GTTag tagByCreatingTagNamed:@"a_new_tag" target:originalTag.target message:@"my tag\n" tagger:originalTag.tagger force:NO inRepository:repository error:&error];
		expect(error).to.beNil();
		expect(tag).notTo.beNil();
		expect(tag.type).to.equal(@"tag");
		expect(tag.message).to.equal(@"my tag\n");
		expect(tag.name).to.equal(@"a_new_tag");
		expect(tag.target.SHA).to.equal(@"5b5b025afb0b4c913b4c338a42934a3863bf3644");
		expect(tag.targetType).to.equal(GTObjectTypeCommit);
	});

	it(@"should fail to create an already existing tag", ^{
		NSError *error = nil;
		GTTag *tag = [GTTag tagByCreatingTagNamed:originalTag.name target:originalTag.target message:@"my tag\n" tagger:originalTag.tagger force:NO inRepository:repository error:&error];
		expect(tag).to.beNil();
		expect(error.domain).to.equal(GTGitErrorDomain);
		expect(error.code).to.equal(GIT_EEXISTS);
	});

	it(@"should delete an existing tag if `force` is YES", ^{
		NSError *error = nil;
		GTTag *tag = [GTTag tagByCreatingTagNamed:originalTag.name target:originalTag.target message:@"my tag\n" tagger:originalTag.tagger force:YES inRepository:repository error:&error];
		expect(tag).notTo.beNil();
		expect(error).to.beNil();
	});
});

describe(@"+tagByCreatingLightweightTagNamed:target:force:inRepository:error:", ^{
	__block NSString *originalTagSHA = nil;
	__block GTTag *originalTag = nil;
	beforeEach(^{
		originalTagSHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
		originalTag = [GTTag lookupWithSHA:originalTagSHA inRepository:repository error:NULL];
	});

	it(@"should create a new lightweight tag", ^{
		NSError *error = nil;
		GTReference *tagReference = [GTTag tagByCreatingLightweightTagNamed:@"another-tag" target:originalTag.target force:NO inRepository:repository error:&error];
		expect(tagReference).notTo.beNil();
		expect(error).to.beNil();
		expect(tagReference.targetSHA).to.equal(originalTag.target.SHA);
	});

	it(@"should fail to create an already existing tag", ^{
		NSError *error = nil;
		GTReference *tagReference = [GTTag tagByCreatingLightweightTagNamed:originalTag.name target:originalTag.target force:NO inRepository:repository error:&error];
		expect(tagReference).to.beNil();
		expect(error.domain).to.equal(GTGitErrorDomain);
		expect(error.code).to.equal(GIT_EEXISTS);
	});

	it(@"should delete an existing tag if `force` is YES", ^{
		NSError *error = nil;
		GTReference *tagReference = [GTTag tagByCreatingLightweightTagNamed:originalTag.name target:originalTag.target force:YES inRepository:repository error:&error];
		expect(tagReference).notTo.beNil();
		expect(error).to.beNil();
	});
});

SpecEnd
