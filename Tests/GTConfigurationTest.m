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

- (void) testCanAddRemote {
    GTConfiguration *configuration = repo.configuration;
    GHAssertNotNil(configuration, @"Couldn't get the configuration");
    
    [configuration addRemote:@"github" withCloneURL:[NSURL URLWithString:@"git://github.com/libgit2/objective-git.git"]];

    NSURL *configFileURL = [NSURL fileURLWithPath:[TEST_REPO_PATH() stringByAppendingPathComponent:@"/config"]];
    
	NSError *error = nil;
    NSString *contentsOfGitConfig = [NSString stringWithContentsOfURL:configFileURL encoding:[NSString defaultCStringEncoding] error:&error];
    
    GHAssertNotNil(contentsOfGitConfig, [NSString stringWithFormat:@"NSError was returned by stringWithContentsOfURL: %@", [error localizedDescription]]);
    BOOL success = [contentsOfGitConfig rangeOfString:@"remote \"github\""].location != NSNotFound;
    
    GHAssertTrue(success, @"properly formatted remote name not found");
}

- (void)testCanAddBranch {
    GTConfiguration *configuration = repo.configuration;
    GHAssertNotNil(configuration, @"Couldn't get the configuration");
    
    [configuration addBranch:@"cocoa_love" trackingRemoteName:nil];
	
    NSURL *configFileURL = [NSURL fileURLWithPath:[TEST_REPO_PATH() stringByAppendingPathComponent:@"/config"]];
    
	NSError *error = nil;
    NSString *contentsOfGitConfig = [NSString stringWithContentsOfURL:configFileURL encoding:[NSString defaultCStringEncoding] error:&error];
    
    GHAssertNotNil(contentsOfGitConfig, [NSString stringWithFormat:@"NSError was returned by stringWithContentsOfURL: %@", [error localizedDescription]]);
    BOOL success = [contentsOfGitConfig rangeOfString:@"branch \"cocoa_love\""].location != NSNotFound;
    
    GHAssertTrue(success, @"properly formatted branch name not found");
}

@end
