//
//  TestAppDelegate.m
//  Test
//
//  Created by Joe Ricioppo on 9/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TestAppDelegate.h"
#import "TestAppWindowController.h"

@implementation TestAppDelegate

@synthesize windowController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

	self.windowController = [[TestAppWindowController alloc] initWithWindowNibName:@"TestAppWindow"];
	[self.windowController showWindow:self];
}

@end
