//
//  GTTagTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"

@interface GTTagTest : GHTestCase {

}
@end

@implementation GTTagTest

- (void)tearDownClass {
	
	// make sure our memory mgt is working
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}

- (void)testCanReadTagData {
	
	NSError *error = nil;
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	GTTag *tag = (GTTag *)[repo lookup:sha error:&error];
	
	GHAssertNotNil(tag, nil);
	GHAssertNil(error, nil);
	GHAssertEqualStrings(sha, tag.sha, nil);
	GHAssertEqualStrings(@"tag", tag.type, nil);
	GHAssertEqualStrings(@"test tag message\n", tag.message, nil);
	GHAssertEqualStrings(@"v1.0", tag.name, nil);
	GHAssertEqualStrings(@"5b5b025afb0b4c913b4c338a42934a3863bf3644", tag.target.sha, nil);
	GHAssertEqualStrings(@"commit", tag.targetType, nil);
	
	GTSignature *c = tag.tagger;
	GHAssertEqualStrings(@"Scott Chacon", c.name, nil);
	GHAssertEquals(1288114383, (int)[c.time timeIntervalSince1970], nil);
	GHAssertEqualStrings(@"schacon@gmail.com", c.email, nil);
}

- (void)testCanWriteTagData {

	NSError *error = nil;
	NSString *sha = @"0c37a5391bbff43c37f0d0371823a5509eed5b1d";
	GTRepository *repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	GTTag *tag = (GTTag *)[repo lookup:sha error:&error];
	
	tag.message = @"new message";
	[tag writeAndReturnError:&error];
	
	GHAssertNil(error, nil);
	GHAssertNotEqualStrings(tag.sha, sha, nil);
	
	rm_loose(tag.sha);
}

@end
