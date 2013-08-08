//
//  NSArray+Pathspec.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 08/08/2013.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "git2.h"

@interface NSArray (Pathspec)

- (git_strarray)git_StringArray;

@end
