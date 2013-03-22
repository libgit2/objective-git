//
//  GTTestCase.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/22/13.
//  Copyright (c) 2013 GitHub, Inc. All rights reserved.
//

#define SPT_SUBCLASS GTTestCase
#import "Specta.h"

@class GTRepository;

@interface GTTestCase : SPTSenTestCase

// Find and return the fixture repository with the given name;
- (GTRepository *)fixtureRepositoryNamed:(NSString *)name;

@end
