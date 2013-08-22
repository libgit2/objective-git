//
//  NSArray+StringArray.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSArray+StringArray.h"

@implementation NSArray (StringArray)

- (git_strarray *)git_strarray {
	if (self.count < 1) return NULL;
	
	char *cStrings[self.count];
	for (NSUInteger idx = 0; idx < self.count; idx++) {
		NSString *string = self[idx];
		NSAssert([string isKindOfClass:NSString.class], @"A string array must only contain NSStrings");
		
		cStrings[idx] = strdup(string.UTF8String);
	}
	
	git_strarray strArray = {.strings = cStrings, .count = self.count};
	git_strarray *copiedString = malloc(sizeof(git_strarray));
	git_strarray_copy(copiedString, &strArray);
	return copiedString;
}

@end
