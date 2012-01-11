//
//  NSError+Git.h
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

extern NSString * const GTGitErrorDomain;


@interface NSError (Git)

// Creates an error for the given libgit2 error code. The returned error's NSLocalizedDescriptionKey is filled with `git_lasterror` or `strerror` if an OS error occurs.
//
// code - the libgit2 error code
//
// returns the created error object
+ (NSError *)git_errorFor:(NSInteger)code;

// Creates an error for the given libgit2 error code. The returned error's NSLocalizedDescriptionKey is filled the given description with `git_lasterror` or `strerror` if an OS error occurs appended on the end.
//
// code - the libgit2 error code
//
// returns the created error object
+ (NSError *)git_errorFor:(NSInteger)code withAdditionalDescription:(NSString *)desc;

/* Error helpers for common libgit2 errors */
+ (NSError *)git_errorForMkStr: (NSInteger)code;

@end
