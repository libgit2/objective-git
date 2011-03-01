//
//  NSString+Git.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/18/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (Git)

+ (const char*)utf8StringForString:(NSString *)str;
+ (NSString *)stringForUTF8String:(const char*)str;

@end
