//
//  NSArray+StringArray.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSArray+StringArray.h"

@implementation NSArray (StringArray)

- (git_strarray *)git_StringArray {
	git_strarray *returnArray = malloc(sizeof(git_strarray));
	returnArray->count = 0;
	returnArray->strings = NULL;
	if (self.count < 1) return returnArray;
	
	NSUInteger actualStringCount = 0;
	char **cStrings = (char **)malloc(self.count * sizeof(char *));
	for (NSUInteger idx = 0; idx < self.count; idx ++) {
		NSString *string = self[idx];
		if (![string isKindOfClass:NSString.class]) continue;
		
		cStrings[idx] = (char *)[string cStringUsingEncoding:NSUTF8StringEncoding];
		actualStringCount ++;
	}
	
	returnArray->strings = cStrings;
	returnArray->count = actualStringCount;
	return returnArray;
}

@end
