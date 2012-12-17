//
//  TestAppWindowController.h
//  Test
//
//  Created by Joe Ricioppo on 9/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
// duuuuuuuude

#import <Cocoa/Cocoa.h>
#import <BWToolkitFramework/BWToolkitFramework.h>

@interface TestAppWindowController : NSWindowController {}

@property (nonatomic, copy) NSString *searchString;
@property (nonatomic, retain) IBOutlet BWStyledTextField *searchField;

@property (nonatomic, retain) NSArray *searchPredicates;
@property (nonatomic, retain) IBOutlet BWTransparentPopUpButton *searchPredicatePopupButton;

@property (nonatomic, copy) NSArray *searchResults;
@property (nonatomic, retain) IBOutlet NSArrayController *searchResultsArrayController;
@property (nonatomic, retain) IBOutlet BWTransparentTableView *searchRelultsTableView;


- (IBAction)searchGitHub:(id)sender;

@end
