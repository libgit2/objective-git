//
//  GTRawObject.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/24/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
/*
#import "GTRawObject.h"
#import "NSString+Git.h"


@implementation GTRawObject

- (void)dealloc {
	
	self.data = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark API

@synthesize type;
@synthesize data;

- (id)initWithType:(GTObjectType)theType data:(NSData *)theData {
	
	if((self = [super init])) {
		self.type = theType;
		self.data = theData;
	}
	return self;
}
+ (id)rawObjectWithType:(GTObjectType)theType data:(NSData *)theData {
	
	return [[[self alloc] initWithType:theType data:theData] autorelease];
}

- (id)initWithType:(GTObjectType)theType string:(NSString *)string {
	
	if((self = [super init])) {
		self.type = theType;
		self.data = [string dataUsingEncoding:NSUTF8StringEncoding];
	}
	return self;
}
+ (id)rawObjectWithType:(GTObjectType)theType string:(NSString *)string {
	
	return [[[self alloc] initWithType:theType string:string] autorelease];
}

- (id)initWithRawObject:(const git_rawobj *)obj {
	
	if((self = [super init])) {
		self.type = obj->type;
		self.data = [NSData dataWithBytes:obj->data length:obj->len];
	}
	return self;
}
+ (id)rawObjectWithRawObject:(const git_rawobj *)obj {
	
	return [[[self alloc] initWithRawObject:obj] autorelease];
}

- (NSString *)dataAsUTF8String {
	
	if(!self.data) return nil;
	
	return [NSString stringWithUTF8String:[data bytes]];
}

- (void)mapToObject:(git_rawobj *)obj {
	
	obj->type = self.type;
	obj->len = 0;
	obj->data = NULL;
	if (self.data != nil) {
		obj->len = [self.data length];
		obj->data = malloc(obj->len);
		memcpy(obj->data, [self.data bytes], obj->len);
	}
}

@end
*/