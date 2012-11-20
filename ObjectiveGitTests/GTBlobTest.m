//
//  GTBlobTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/25/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "Contants.h"

@interface GTBlobTest : SenTestCase {
	
	GTRepository *repo;
	NSString *sha;
}
@end

@implementation GTBlobTest

- (void)setUp {
	
	NSError *error = nil;
    repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
	sha = @"fa49b077972391ad58037050f2a75f74e3671e92";
}

- (void)testCanReadBlobData {
	
	NSError *error = nil;
	GTBlob *blob = (GTBlob *)[repo lookupObjectBySha:sha error:&error];
	STAssertEquals(9, (int)blob.size, nil);
	STAssertEqualObjects(@"new file\n", blob.content, nil);
	STAssertEqualObjects(@"blob", blob.type, nil);
	STAssertEqualObjects(sha, blob.sha, nil);
}

// todo
/*
- (void)testCanRewriteBlobData {
	
	NSError *error = nil;
	GTBlob *blob = (GTBlob *)[repo lookupBySha:sha error:&error];
	blob.content = @"my new content";
	STAssertEqualObjects(sha, blob.sha, nil);
	
	NSString *newSha = [blob writeAndReturnError:&error];
	
	STAssertNil(error, [error localizedDescription]);
	STAssertEqualObjects(@"2dd916ea1ff086d61fbc1c286079305ffad4e92e", blob.sha, nil);
	STAssertEqualObjects(@"2dd916ea1ff086d61fbc1c286079305ffad4e92e", newSha, nil);
	rm_loose(blob.sha);
}
*/

- (void)testCanWriteNewBlobData {
	
	NSError *error = nil;
    GTBlob *blob = [GTBlob blobWithString:@"a new blob content" inRepository:repo error:&error];
    NSString *newSha = [blob sha];
	STAssertNotNil(newSha, [error localizedDescription]);
	
	rm_loose(self.class, newSha);
}

- (void)testCanWriteNewBlobData2 {
	
	NSError *error = nil;
    GTBlob *blob = [GTBlob blobWithString:@"a new blob content" inRepository:repo error:&error];
	STAssertNotNil(blob, [error localizedDescription]);
	
	rm_loose(self.class, blob.sha);
}

//- (void)testCanGetCompleteContentWithNulls {
//	
//	NSError *error = nil;
//	char bytes[] = "100644 example_helper.rb\00\xD3\xD5\xED\x9D A4_\x00 40000 examples";
//	NSData *content = [NSData dataWithBytes:bytes length:sizeof(bytes)];
//	
//	GTBlob *blob = [GTBlob blobWithData:content inRepository:repo error:&error];
//    NSString *newSha = [blob sha];
//	STAssertNotNil(newSha, [error localizedDescription]);
//	
//	rm_loose(self.class, newSha);
//	
//	//todo
//	/*GTRawObject *obj = [GTRawObject rawObjectWithType:GTObjectTypeBlob data:content];
//	NSString *newSha = [repo write:obj error:&error];
//	
//	STAssertNil(error, [error localizedDescription]);
//	STAssertNotNil(newSha, nil);
//	GTBlob *blob = (GTBlob *)[repo lookupBySha:newSha error:&error];
//	GTRawObject *newObj = [blob readRawAndReturnError:&error];
//	STAssertNil(error, [error localizedDescription]);
//	NSLog(@"original content = %@", [obj data]);
//	NSLog(@"lookup content   = %@", [newObj data]);
//	STAssertEqualObjects(newObj.data, obj.data, nil);
//	rm_loose(newSha);*/
//}

// todo
//- (void)testCanCreateBlobFromFile {
//	
//}

@end
