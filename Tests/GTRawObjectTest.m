//
//  GTRawObjectTest.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/17/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import "Contants.h"
#import "NSString+Git.h"

@interface GTRawObjectTest : GHTestCase {
	
}
@end

@implementation GTRawObjectTest

- (void)testCanMapToObject {
	
	GTRawObject *rawObj = [GTRawObject rawObjectWithType:GTObjectTypeBlob string:@"Test"];
	git_rawobj obj;
	[rawObj mapToObject:&obj];
	GHAssertEquals(rawObj.type, obj.type, nil);
	GHAssertEquals(4, (int)obj.len, nil);
	GHAssertEqualStrings(@"Test", [NSString stringForUTF8String:(const char *)obj.data], nil);
}

@end