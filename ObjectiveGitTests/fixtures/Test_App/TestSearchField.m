//
//  TestSearchField.m
//  Test
//
//  Created by Joe Ricioppo on 9/29/10.
//  Copyright 2010 GitHub. All rights reserved.
//

#import "TestSearchField.h"
#import "TestSearchFieldCell.h"

@implementation TestSearchField

+ (Class)cellClass {

	return [TestSearchFieldCell class];
}

- (id) initWithFrame:(NSRect)frame {

	if (self = [super initWithFrame:frame]) {

		self.drawsBackground = NO;
	}

	return self;
}

@end
