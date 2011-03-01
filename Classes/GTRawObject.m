//
//  GTRawObject.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/24/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTRawObject.h"
#import "NSString+Git.h"

@implementation GTRawObject

@synthesize type;
@synthesize data;

+ (id)rawObjectWithType:(git_otype)theType data:(NSData *)theData {
	
	return [[[GTRawObject alloc] initWithType:theType data:theData] autorelease];
}

+ (id)rawObjectWithType:(git_otype)theType string:(NSString *)string {
	
	return [[[GTRawObject alloc] initWithType:theType string:string] autorelease];
}

- (id)initWithType:(git_otype)theType data:(NSData *)theData {
	
	if(self = [super init]) {
		self.type = theType;
		self.data = theData;
	}
	return self;
}

- (id)initWithType:(git_otype)theType string:(NSString *)string {
	
	if(self = [super init]) {
		self.type = theType;
		self.data = [string dataUsingEncoding:NSUTF8StringEncoding];
	}
	return self;
}

- (NSString *)dataAsUTF8String {
	
	if(!self.data) return nil;
	
	return [NSString stringWithUTF8String:[data bytes]];
}

@end
