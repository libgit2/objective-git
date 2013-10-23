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

// Describes the given libgit2 error code, using any message provided by libgit2
// or the OS.
//
// code - The error code returned from libgit2.
//
// Returns a non-nil NSError.
+ (NSError *)git_errorFor:(int)code;

// Describes the given libgit2 error code, using `desc` as the error's
// description, and a failure reason from `reason` and the arguments that
// follow.
//
// The created error will also have an `NSUnderlyingErrorKey` that contains the
// result of +git_errorFor: on the same error code.
//
// code   - The error code returned from libgit2.
// desc   - The description to use in the created NSError. This may be nil.
// reason - A format string to use for the created NSError's failure reason.
//          This may be nil.
// ...    - Format arguments to insert into `reason`.
//
// Returns a non-nil NSError.
+ (NSError *)git_errorFor:(int)code description:(NSString *)desc failureReason:(NSString *)reason, ... NS_FORMAT_FUNCTION(3, 4);

// Describes the given libgit2 error code, using `desc` and the arguments that
// follow as the error's description.
//
// The created error will also have an `NSUnderlyingErrorKey` that contains the
// result of +git_errorFor: on the same error code.
//
// code - The error code returned from libgit2.
// desc - A format string to use for the created NSError's description. This may be nil.
// ...  - Format arguments to insert into `desc`.
//
// Returns a non-nil NSError.
+ (NSError *)git_errorFor:(int)code description:(NSString *)desc, ... NS_FORMAT_FUNCTION(2, 3);

@end
