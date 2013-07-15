//
//  GTRemote.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

@class GTRepository;

@interface GTRemote : NSObject

@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *URLString;

+ (instancetype)remoteWithName:(NSString *)name inRepository:(GTRepository *)repo;
- (instancetype)initWithName:(NSString *)name inRepository:(GTRepository *)repo;

- (id)initWithGitRemote:(git_remote *)remote;

// The underlying `git_remote` object.
- (git_remote *)git_remote __attribute__((objc_returns_inner_pointer));

@end
