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

// Creates and returns a `git_strarray` given an `NSArray` of `NSString`s.
//
// If any object in the array is not an `NSString` it is skipped over.
- (git_strarray *)git_StringArray;

@end
