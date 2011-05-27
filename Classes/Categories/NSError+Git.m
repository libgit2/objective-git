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
#import <git2.h>

NSString * const GTGitErrorDomain = @"GTGitErrorDomain";

@implementation NSError (Git)

+ (NSError *)git_errorWithDescription:(NSString *)desc {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:-1
						   userInfo:
			[NSDictionary dictionaryWithObject:desc
										forKey:NSLocalizedDescriptionKey]];
}

+ (NSError *)git_errorFor:(int)code withDescription:(NSString *)desc {
	
	NSString *gitErrorDesc = [NSString stringWithUTF8String:git_lasterror()];
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ %@", desc, gitErrorDesc]
										forKey:NSLocalizedDescriptionKey]];
}

+ (NSError *)git_errorFor:(int)code {
	
	return [NSError errorWithDomain:GTGitErrorDomain
							   code:code
						   userInfo:
			[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:git_lasterror()]
										forKey:NSLocalizedDescriptionKey]];
}

+ (NSError *)git_errorForMkStr: (int)code {
	
	return [NSError git_errorFor:code withDescription:@"Failed to create object id from sha1."];
}

+ (NSError *)git_errorForAddEntryToIndex: (int)code {
	
	return [NSError git_errorFor:code withDescription:@"Failed to add entry to index."];
}

@end
