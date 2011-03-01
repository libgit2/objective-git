//
//  GTLibTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "Contants.h"
#import "NSData+Base64.h"


@interface GTLibTest : GHTestCase {}
@end


@implementation GTLibTest

- (void)testCanConvertHexToRaw {
	
	NSData *raw = [GTLib hexToRaw:@"ce08fe4884650f067bd5703b6a59a8b3b3c99a09"];
	
	NSString *b64raw = [raw base64EncodedString];
	GHAssertEqualStrings(@"zgj+SIRlDwZ71XA7almos7PJmgk=", b64raw, nil);
}

- (void)testCanConvertRawToHex {
	
	NSString *rawb64 = @"FqASNFZ4mrze9Ld1ITwjqL109eA=";
	NSData *raw = [NSData dataFromBase64String:rawb64];
	NSString *hex = [GTLib rawToHex:raw];
	
	GHAssertEqualStrings(hex, @"16a0123456789abcdef4b775213c23a8bd74f5e0", nil);
}

@end
