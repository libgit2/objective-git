//
//  GTConfigurationTest.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/30/11.
//  Copyright (c) 2011 GitHub, Inc. All rights reserved.
//

#import "Contants.h"
#import "GTConfiguration.h"

@interface GTConfigurationTest : GHTestCase {	
	GTRepository *repo;
}
@end


@implementation GTConfigurationTest

- (void)setUp {
	NSError *error = nil;
    repo = [GTRepository repositoryWithURL:[NSURL fileURLWithPath:TEST_REPO_PATH()] error:&error];
}

- (void)testCanSetUserName {
	GTConfiguration *configuration = repo.configuration;
	GHAssertNotNil(configuration, @"Couldn't get the configuration");

	static NSString * const setUserName = @"josh@github.com";
	[configuration setString:setUserName forKey:@"user.name"];
	NSString *userName = [configuration stringForKey:@"user.name"];
	GHAssertEqualStrings(userName, setUserName, @"Name didn't match: %@", userName);
}

- (void)testCanDeleteUserName {
	GTConfiguration *configuration = repo.configuration;
	GHAssertNotNil(configuration, @"Couldn't get the configuration");
	
	NSError *error = nil;
	BOOL success = [configuration deleteValueForKey:@"user.name" error:&error];
	GHAssertTrue(success, [error localizedDescription]);
}

@end
