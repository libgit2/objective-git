//
//  GTRemote.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@interface GTRemote : NSObject

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *URLString;

- (id)initWithGitRemote:(git_remote *)remote;

// The underlying `git_remote` object.
- (git_remote *)git_remote __attribute__((objc_returns_inner_pointer));


// Updates the URL String for this remote
- (BOOL)updateURLString:(NSString *)URLString error:(NSError **)error;

@end
