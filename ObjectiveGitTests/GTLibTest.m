//
//  Test.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
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
#import "NSData+Git.h"
#import "NSString+Git.h"

@interface Test : SenTestCase {}
@end

@implementation Test

- (void)testCanConvertHexToRaw {
	
	NSError *error = nil;
    git_oid oid;
    NSString *sha = @"ce08fe4884650f067bd5703b6a59a8b3b3c99a09";
    STAssertTrue([sha git_getOid:&oid error:&error], nil);
	NSData *raw = [NSData git_dataWithOid:&oid];
	STAssertNil(error, [error localizedDescription]);
	
	NSString *b64raw = [raw git_base64EncodedString];
	STAssertEqualObjects(@"zgj+SIRlDwZ71XA7almos7PJmgk=", b64raw, nil);
}

- (void)testCanConvertRawToHex {
	
	NSString *rawb64 = @"FqASNFZ4mrze9Ld1ITwjqL109eA=";
	NSData *raw = [NSData git_dataWithBase64String:rawb64];
    git_oid oid;
    NSError *error = nil;
    [raw git_getOid:&oid error:&error];
    STAssertNil(error, [error localizedDescription]);
	NSString *hex = [NSString git_stringWithOid:&oid];
	
	STAssertEqualObjects(hex, @"16a0123456789abcdef4b775213c23a8bd74f5e0", nil);
}

@end
