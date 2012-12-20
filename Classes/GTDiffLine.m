//
//  GTDiffLine.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 20/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffLine.h"

@implementation GTDiffLine

- (instancetype)initWithContent:(NSString *)content oldLineNumber:(NSInteger)oldLineNumber newLineNumber:(NSInteger)newLineNumber origin:(GTDiffLineOrigin)origin {
	self = [super init];
	if (self == nil) return nil;
	
	_content = [content copy];
	_oldLineNumber = oldLineNumber;
	_newLineNumber = newLineNumber;
	_origin = origin;
	
	return self;
}

@end
