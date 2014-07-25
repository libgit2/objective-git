//
//  GTRepository+Attributes.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 7/25/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Attributes.h"
#import "NSError+Git.h"

@implementation GTRepository (Attributes)

- (NSString *)attributeWithName:(NSString *)name path:(NSString *)path {
	const char *val = NULL;
	git_attr_get(&val, self.git_repository, 0, path.UTF8String, name.UTF8String);
	if (val == NULL) return nil;

	return @(val);
}

@end
