//
//  NSArray+StringArray.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSArray+StringArray.h"

@implementation NSArray (StringArray)

- (git_strarray)git_StringArray {
	char *cStrings[self.count];
	if (self.count < 1) return (git_strarray){}; //?
	
	NSUInteger actualStringCount = 0;
	for (NSUInteger idx = 0; idx < self.count; idx ++) {
		NSString *string = self[idx];
		if (![string isKindOfClass:NSString.class]) continue;
		
		cStrings[idx] = (char *)[string cStringUsingEncoding:NSUTF8StringEncoding];
		actualStringCount ++;
	}
	
	git_strarray strArray = {.strings = cStrings, .count = actualStringCount};
	return strArray;
}

@end
