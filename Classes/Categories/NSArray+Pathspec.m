//
//  NSArray+Pathspec.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSArray+Pathspec.h"

@implementation NSArray (Pathspec)

- (git_strarray)git_StringArray {
	char *cStrings[self.count];
	if (self.count < 1) return (git_strarray){}; //?
	
	for (NSUInteger idx = 0; idx < self.count; idx ++) {
		cStrings[idx] = (char *)[self[idx] cStringUsingEncoding:NSUTF8StringEncoding];
	}
	
	git_strarray strArray = {.strings = cStrings, .count = self.count};
	return strArray;
}

@end
