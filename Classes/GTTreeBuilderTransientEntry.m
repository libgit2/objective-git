//
//  GTTreeBuilderTransientEntry.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/27/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import "GTTreeBuilderTransientEntry.h"

@implementation GTTreeBuilderTransientEntry

#pragma Lifecycle

- (id)initWithFileName:(NSString *)fileName data:(NSData *)data fileMode:(GTFileMode)fileMode {
	NSParameterAssert(fileName != nil);
	NSParameterAssert(data != nil);

	self = [super init];
	if (self == nil) return nil;

	_fileName = [fileName copy];
	_data = data;
	_fileMode = fileMode;

	return self;
}

@end
