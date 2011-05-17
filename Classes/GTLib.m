//
//  GTLib.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/18/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <git2.h>
#import "GTLib.h"
#import "NSError+Git.h"


@implementation GTLib

#pragma mark -
#pragma mark API 

+ (NSData *)hexToRaw:(NSString *)hex error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_oid_mkstr(&oid, [hex UTF8String]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}

	return [NSData dataWithBytes:oid.id length:20];
}

+ (NSString *)rawToHex:(NSData *)raw {
	
	git_oid oid;
	
	git_oid_mkraw(&oid, [raw bytes]);
	return [GTLib convertOidToSha:&oid];
}

+ (NSString *)convertOidToSha:(git_oid const *)oid {
	
	char hex[41];
	git_oid_fmt(hex, oid);
	hex[40] = 0;
	return [NSString stringWithUTF8String:hex];
}

+ (BOOL)convertSha:(NSString *)sha toOid:(git_oid *)oid error:(NSError **)error {
	
	int gitError = git_oid_mkstr(oid, [sha UTF8String]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return NO;
	}
	return YES;
}

+ (NSString *)shortUniqueShaFromSha:(NSString *)sha {
	
	// Kyle says with a length of 6 our chances of collision are 9.6e-29, so we'll take those odds
	// todo: Vicent wrote something to do this officially: consider using it instead
	static const NSUInteger magicUniqueLength = 6;
	return [sha substringToIndex:magicUniqueLength];
}

@end
