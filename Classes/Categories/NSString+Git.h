//
//  NSString+Git.m
//  ObjectiveGitFramework
//
//  Created by Dave DeLong on 5/20/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Dave DeLong
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

#include "git2.h"

@interface NSString (Git)

// Turn an Oid into a sha1 hash
// 
// oid - the raw git_oid to convert
//
// returns an NSString of the sha1
+ (NSString *)git_stringWithOid:(const git_oid *)oid;

// Get a short unique sha1 for a full sha1
//
// returns a NSString of the shortened sha1
// returns nil if the receiver is not a sha string or is too short
- (NSString *)git_shortUniqueShaString;

// Turn a sha1 hash into an Oid
// 
// oid(out) - the converted oid
// error(out) - will be filled if an error occurs
//
// returns YES if successful and NO if a failure occurred.
- (BOOL)git_getOid:(git_oid *)oid error:(NSError **)error;

@end
