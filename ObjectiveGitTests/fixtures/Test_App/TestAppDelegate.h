//
//  TestAppDelegate.h
//  Test
//
//  Created by Joe Ricioppo on 9/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TestAppWindowController;

@interface TestAppDelegate : NSObject <NSApplicationDelegate> {}

@property (nonatomic, retain) TestAppWindowController *windowController;

@end
