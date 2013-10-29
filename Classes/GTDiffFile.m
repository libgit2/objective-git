//
//  GTDiffFile.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffFile.h"
#import "GTOID.h"

@interface GTDiffFile ()

@property (nonatomic, copy) GTOID *OID;

@end

@implementation GTDiffFile

- (instancetype)initWithGitDiffFile:(git_diff_file)file {
	self = [super init];
	if (self == nil) return nil;
	
	_git_diff_file = file;
	
	_size = (NSUInteger)file.size;
	_flags = (GTDiffFileFlag)file.flags;
	_mode = file.mode;
	_path = [NSString stringWithUTF8String:file.path];
	
	return self;
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ path: %@, size: %ld, mode: %u, flags: %u", super.debugDescription, self.path, (unsigned long)self.size, self.mode, self.flags];
}

- (GTOID *)OID {
	if (!_OID) {
		_OID = [[GTOID alloc] initWithGitOid:&_git_diff_file.oid];
	}
	return [_OID copy];
}

@end
