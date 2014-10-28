//
//  GTDiffFile.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffFile.h"
#import "GTOID.h"

@implementation GTDiffFile

- (instancetype)initWithGitDiffFile:(git_diff_file)file {
	NSParameterAssert(file.path != NULL);

	self = [super init];
	if (self == nil) return nil;

	_path = @(file.path);
	if (_path == nil) return nil;

	_git_diff_file = file;
	_size = (NSUInteger)file.size;
	_flags = (GTDiffFileFlag)file.flags;
	_mode = file.mode;

	return self;
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ path: %@, size: %ld, mode: %u, flags: %@", super.debugDescription, self.path, (unsigned long)self.size, self.mode, @(self.flags)];
}

- (GTOID *)OID {
	return [[GTOID alloc] initWithGitOid:&_git_diff_file.id];
}

@end
