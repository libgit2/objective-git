//
//  GTRepository+References.h
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 6/4/15.
//  Copyright (c) 2015 GitHub, Inc. All rights reserved.
//

#import "GTrepository.h"

@class GTReference;

@interface GTRepository (References)

- (GTReference *)lookUpReferenceWithName:(NSString *)name error:(NSError **)error;

@end
