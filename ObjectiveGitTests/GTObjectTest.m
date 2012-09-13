//
//  GTObjectTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/24/11.
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

@interface GTObjectTest : SenTestCase {
	
	GTRepository *repo;
}
@end

@implementation GTObjectTest

- (void)setUp {
	
	NSError *error = nil;
    repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH(self.class)] error:&error];
}

- (void)testCanLookupEmptyStringFails {
	
	NSError *error = nil;
	GTObject *obj = [repo lookupObjectBySha:@"" error:&error];
	
	STAssertNotNil(error, nil);
	STAssertNil(obj, nil);
	NSLog(@"Error = %@", [error localizedDescription]);
}

- (void)testCanLookupBadObjectFails {
	
	NSError *error = nil;
	GTObject *obj = [repo lookupObjectBySha:@"a496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	STAssertNotNil(error, nil);
	STAssertNil(obj, nil);
	NSLog(@"Error = %@", [error localizedDescription]);
}

- (void)testCanLookupAnObject {
	
	NSError *error = nil;
	GTObject *obj = [repo lookupObjectBySha:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	STAssertNil(error, [error localizedDescription]);
	STAssertNotNil(obj, nil);
	STAssertEqualObjects(obj.type, @"commit", nil);
	STAssertEqualObjects(obj.sha, @"8496071c1b46c854b31185ea97743be6a8774479", nil);
}

- (void)testTwoObjectsAreTheSame {
	
	NSError *error = nil;
	GTObject *obj1 = [repo lookupObjectBySha:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	GTObject *obj2 = [repo lookupObjectBySha:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	STAssertNotNil(obj1, nil);
	STAssertNotNil(obj2, nil);
	STAssertTrue([obj1 isEqual:obj2], nil);
}

- (void)testCanReadRawDataFromObject {
	
	NSError *error = nil;
	GTObject *obj = [repo lookupObjectBySha:@"8496071c1b46c854b31185ea97743be6a8774479" error:&error];
	
	STAssertNotNil(obj, nil);
	
	GTOdbObject *rawObj = [obj odbObjectWithError:&error];
	STAssertNotNil(rawObj, nil);
	STAssertNil(error, [error localizedDescription]);
	NSLog(@"rawObj len = %ld", [rawObj.data length]);
}

@end
