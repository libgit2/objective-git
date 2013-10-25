//
//  GTDiffLine.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 20/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffLine.h"

@implementation GTDiffLine

- (instancetype)initWithGitLine:(const git_diff_line *)line {
	self = [super init];
	if (self == nil) return nil;
	
	_contents = [[[NSString alloc] initWithBytes:line->content length:line->content_len encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
	_oldLineNumber = line->old_lineno;
	_newLineNumber = line->new_lineno;
	_origin = line->origin;
	_numLines = line->num_lines;
	
	return self;
}

@end
