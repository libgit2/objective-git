//
//  NSArray+StringArray.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSArray+StringArray.h"

@implementation NSArray (StringArray)

+ (instancetype)git_arrayWithStrArray:(git_strarray)strarray {
	return [[NSMutableArray git_arrayWithStrArray:strarray] copy];
}

- (git_strarray)git_strarray {
	if (self.count < 1) return (git_strarray){ .strings = NULL, .count = 0 };
	
	char **cStrings = malloc(self.count * sizeof(char *));
	for (NSUInteger idx = 0; idx < self.count; idx++) {
		NSString *string = self[idx];
		NSAssert([string isKindOfClass:NSString.class], @"A string array must only contain NSStrings. %@ is not a string.", string);
		
		cStrings[idx] = strdup(string.UTF8String);
	}
	
	git_strarray strArray = { .strings = cStrings, .count = self.count };
	return strArray;
}

@end

@implementation NSMutableArray (StringArray)
+ (instancetype)git_arrayWithStrArray:(git_strarray)strarray {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:strarray.count];
	for (NSUInteger i = 0; i < strarray.count; i++) {
		NSString *string = @(strarray.strings[i]);
		if (string == nil) continue;

		[array addObject:string];
	}
	return array;
}
@end
