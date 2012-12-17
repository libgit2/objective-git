//
//  TestAppWindowController.m
//  Test
//
//  Created by Joe Ricioppo on 9/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TestAppWindowController.h"
#import "GHGitHubClient.h"
#import "GHGitHubUser.h"
#import "GHGitRepository.h"

static NSString * const kEverything = @"Everything";
static NSString * const kRepositories = @"Repositories";
static NSString * const kUsers = @"Users";
static NSString * const kCode = @"Code";

enum { GHSearchPredicateEverything = 0, GHSearchPredicateRepositories, GHSearchPredicateUsers, GHSearchPredicateCode};

@interface TestAppWindowController ()
- (NSArray *)unknownUserResults;
@end


@implementation TestAppWindowController

@synthesize searchString;
@synthesize searchField;

@synthesize searchPredicates;
@synthesize searchPredicatePopupButton;

@synthesize searchResults;
@synthesize searchResultsArrayController;
@synthesize searchRelultsTableView;

- (void)dealloc {

	self.searchString = nil;
	self.searchResults = nil;
	self.searchPredicates = nil;
	[super dealloc];
}

#pragma mark -

- (void)windowDidLoad {

	[self.window setHidesOnDeactivate:YES];

	self.searchPredicates = [NSArray arrayWithObjects: kEverything, kRepositories, kUsers, kCode, nil];

	[[GHGitHubClient sharedClient] requestRepositoryWithName:@"controls" forUserWithName:@"joericioppo" completionBlock:^(GHGitRepository *repository, NSError *error) {
		NSLog(@"[%@ %s], repository: %@", self, _cmd, repository);
	}];
}

- (IBAction)searchGitHub:(id)sender {

	NSInteger selectedPredicate = [self.searchPredicatePopupButton indexOfSelectedItem];

	switch (selectedPredicate) {
		case GHSearchPredicateEverything:
			break;
		case GHSearchPredicateRepositories:
			break;
		case GHSearchPredicateUsers:
			[[GHGitHubClient sharedClient] requestRepositoriesForUserWithName:self.searchString completionBlock:^(NSArray *repositories, NSError *error) {
				self.searchResults = repositories ?: [self unknownUserResults];
			}];
			break;
		case GHSearchPredicateCode:
			break;
		default:
			break;
	}
}

- (NSArray *)unknownUserResults {


	// blah blah blah
	return [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"We don't know anyone with that name.." forKey:@"name"]];
}

@end
