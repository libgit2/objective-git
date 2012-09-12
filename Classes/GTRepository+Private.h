//
//  GTRepository+Private.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/30/11.
//  Copyright (c) 2011 GitHub, Inc. All rights reserved.
//

#import "GTRepository.h"

@class GTEnumerator;

@interface GTRepository ()

- (void)addEnumerator:(GTEnumerator *)enumerator;
- (void)removeEnumerator:(GTEnumerator *)enumerator;

@end
