//
//  NSString+Git.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/18/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "NSString+Git.h"


@implementation NSString (Git)


+ (const char*)utf8StringForString:(NSString *)str {
	
	return [str cStringUsingEncoding:NSUTF8StringEncoding];
}

+ (NSString *)stringForUTF8String:(const char*)str {
	
	return [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
}

@end
