//
//  GTLib.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/18/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>
#import "GTLib.h"
#import "NSString+Git.h"


@implementation GTLib

+ (NSData *)hexToRaw:(NSString *)hex {

	git_oid oid;
	git_oid_mkstr(&oid, [NSString utf8StringForString:hex]);

	return [NSData dataWithBytes:oid.id length:20];
}

+ (NSString *)rawToHex:(NSData *)raw {
	
	git_oid oid;
	char hex[41];
	
	git_oid_mkraw(&oid, [raw bytes]);
	git_oid_fmt(hex, &oid);
	hex[40] = 0;
	
	return [NSString stringForUTF8String:hex];
}

@end
