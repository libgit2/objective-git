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

beforeEach(^{
	NSError *error = nil;
	GTRepository *repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	NSString *tagSHA = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	tag = (GTTag *)[repo lookupObjectBySHA:tagSHA error:&error];
	expect(error).to.beFalsy;
	expect(tag).to.beTruthy;
	expect(tagSHA).to.equal(tag.SHA);
});

it(@"can read tag data", ^{
	
	expect(@"tag").to.equal(tag.type);
	expect(@"test tag message\n").to.equal(tag.message);
	expect(@"v1.0").to.equal(tag.name);
	expect(@"5b5b025afb0b4c913b4c338a42934a3863bf3644").to.equal(tag.target.SHA);
	expect(GTObjectTypeCommit).to.equal(tag.targetType);
	
	GTSignature *signature = tag.tagger;
	expect(@"Scott Chacon").to.equal(signature.name);
	expect(1288114383).to.equal((int)[signature.time timeIntervalSince1970]);
	expect(@"schacon@gmail.com").to.equal(signature.email);
	
	
});

SpecEnd
