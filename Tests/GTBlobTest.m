//
//  GTBlobTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/25/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"

@interface GTBlobTest : GHTestCase {
	
	GTRepository *repo;
	NSString *sha;
}
@end

@implementation GTBlobTest

- (void)setUp {
	
	NSError *error = nil;
	repo = [GTRepository repoByOpeningRepositoryInDirectory:[NSURL URLWithString:TEST_REPO_PATH] error:&error];
	sha = @"fa49b077972391ad58037050f2a75f74e3671e92";
}

- (void)tearDownClass {
	
	// make sure our memory mgt is working
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}

- (void)testCanReadBlobData {
	
	NSError *error = nil;
	GTBlob *blob = (GTBlob *)[repo lookup:sha error:&error];
	GHAssertEquals(9, (int)blob.size, nil);
	GHAssertEqualStrings(@"new file\n", blob.content, nil);
	GHAssertEqualStrings(@"blob", blob.type, nil);
	GHAssertEqualStrings(sha, blob.sha, nil);
}

- (void)testCanRewriteBlobData {
	
	NSError *error = nil;
	GTBlob *blob = (GTBlob *)[repo lookup:sha error:&error];
	blob.content = @"my new content";
	GHAssertEqualStrings(sha, blob.sha, nil);
	
	[blob writeAndReturnError:&error];
	
	GHAssertNil(error, nil);
	GHAssertEqualStrings(@"2dd916ea1ff086d61fbc1c286079305ffad4e92e", blob.sha, nil);
	rm_loose(blob.sha);
}

- (void)testCanWriteNewBlobData {
	
	NSError *error = nil;
	GTBlob *blob = [[GTBlob alloc] initInRepo:repo error:&error];
	GHAssertNil(error, nil);
	GHAssertNotNil(blob, nil);
	blob.content = @"a new blob content";
	
	[blob writeAndReturnError:&error];
	GHAssertNil(error, nil);
	
	rm_loose(blob.sha);
}

- (void)testCanGetCompleteContentWithNulls {

	//@"100644 example_helper.rb\x00\xD3\xD5\xED\x9DA4_\xE3\xC3\nK\xCD<!\xEA-_\x9E\xDC=40000 examples\x00\xAE\xCB\xE9d!|\xB9\xA6\x96\x024],U\xEE\x99\xA2\xEE\xD4\x92 ";
	NSError *error = nil;
	char bytes[] = "100644 example_helper.rb\00\xD3\xD5\xED\x9D A4_\x00 40000 examples";
	NSData *content = [NSData dataWithBytes:bytes length:sizeof(bytes)];
	GTRawObject *obj = [GTRawObject rawObjectWithType:GIT_OBJ_BLOB data:content];

	NSString *newSha = [repo write:obj error:&error];

	GHAssertNil(error, nil);
	GHAssertNotNil(newSha, nil);
	GTBlob *blob = (GTBlob *)[repo lookup:newSha error:&error];
	GTRawObject *newObj = [blob readRawAndReturnError:&error];
	GHAssertNil(error, nil);
	GHTestLog(@"original content = %@", [obj data]);
	GHTestLog(@"lookup content   = %@", [newObj data]);
	GHAssertTrue([newObj.data isEqualToData:obj.data], nil);
	rm_loose(newSha);
}

@end
