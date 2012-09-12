//
//  GTConfiguration+Private.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTConfiguration.h"

@class GTRepository;

@interface GTConfiguration ()

@property (nonatomic, readwrite, unsafe_unretained) GTRepository *repository;

@end
