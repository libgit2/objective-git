//
//  NSError+Git.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/17/11.
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

#import "NSError+Git.h"
#include "git2.h"

NSString * const GTGitErrorDomain = @"GTGitErrorDomain";


@implementation NSError (Git)

+ (NSError *)git_errorFor:(NSInteger)code withAdditionalDescription:(NSString *)desc, ... {
	va_list args;
	va_start(args, desc);

	NSString *formattedDesc = [[NSString alloc] initWithFormat:desc arguments:args];
	NSError *error = [self git_errorFor:code description:formattedDesc failureReason:nil];

	va_end(args);
	return error;
}

+ (NSError *)git_errorFor:(NSInteger)code description:(NSString *)desc failureReason:(NSString *)reason, ... {
	va_list args;
	va_start(args, reason);

	NSString *formattedReason = [[NSString alloc] initWithFormat:desc arguments:args];

	va_end(args);

	NSMutableDictionary *userInfo = [@{
		NSLocalizedFailureReasonErrorKey: formattedReason,
		NSLocalizedDescriptionKey: desc,
	} mutableCopy];

	NSError *underError = [self git_errorFor:code];
	if (underError != nil) userInfo[NSUnderlyingErrorKey] = underError;

	return [NSError errorWithDomain:GTGitErrorDomain code:code userInfo:userInfo];
}

+ (NSError *)git_errorFor:(NSInteger)code {
	return [NSError errorWithDomain:GTGitErrorDomain code:code userInfo:[NSDictionary dictionaryWithObject:[self gitLastErrorDescriptionWithCode:code] forKey:NSLocalizedDescriptionKey]];
}

+ (NSError *)git_errorForMkStr:(NSInteger)code {
	return [NSError git_errorFor:code withAdditionalDescription:@"Failed to create object id from sha1."];
}

+ (NSString *)gitLastErrorDescriptionWithCode:(NSInteger)code {
	const git_error *gitLastError = giterr_last();
	if (gitLastError == NULL && code == GITERR_OS) {
		return [NSString stringWithUTF8String:strerror(errno)];
	}

	if (gitLastError != NULL) {
		return [NSString stringWithUTF8String:gitLastError->message];
	} else {
		return nil;
	}
}

@end
