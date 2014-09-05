//
//  NSArray+StringArray.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "NSArray+StringArray.h"
#import "EXTScope.h"

@implementation NSArray (StringArray)

+ (instancetype)git_arrayWithStrarray:(git_strarray)strarray {
	__strong id *strings = (__strong id *)calloc(strarray.count, sizeof(*strings));
	@onExit {
		free(strings);
	};

	size_t stringsCount = 0;
	for (size_t i = 0; i < strarray.count; i++) {
		const char *cStr = strarray.strings[i];
		if (cStr == NULL) continue;

		NSUInteger length = strlen(cStr);
		NSString *string =
			[[NSString alloc] initWithBytes:cStr length:length encoding:NSUTF8StringEncoding]
		?:	[[NSString alloc] initWithBytes:cStr length:length encoding:NSASCIIStringEncoding];
		if (string == nil) continue;

		strings[stringsCount++] = string;
	}

	@onExit {
		// Make sure to set each entry in `strings` to nil, so ARC properly
		// releases its references.
		for (size_t i = 0; i < stringsCount; i++) {
			strings[i] = nil;
		}
	};

	// If any of the strings were nil, we may have fewer objects than
	// `strarray`.
	return [[self alloc] initWithObjects:strings count:stringsCount];
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
