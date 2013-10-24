//
//  NSArray+StringArray.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "git2.h"

@interface NSArray (StringArray)

// Creates and return a new `NSArray` of `NSString` given a `git_strarray`
//
// The `git_strarray` must still be freed using `git_strarray_free`. It also
// works on `NSMutableArray`, returning a mutable copy in this case.
//
// strarray - The `git_strarray` to convert.
//
// Returns a new array with the contents to strarray converted to NSStrings.
+ (instancetype)git_arrayWithStrarray:(git_strarray)strarray;

// Creates and returns a `git_strarray` given an `NSArray` of `NSString`s.
//
// Must only be called with an array of `NSString`s, otherwise an assertion will
// fail.
//
// Returns a `git_strarray` which must be freed using `git_strarray_free` after
// use.
- (git_strarray)git_strarray;

@end
