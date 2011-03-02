//
//  GTSignature.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
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

#import "GTSignature.h"
#import "NSString+Git.h"

@implementation GTSignature

@synthesize signature;
@synthesize name;
@synthesize email;
@synthesize time;

+ (id)signatureWithSignature:(git_signature *)theSignature {
	
	return [[[GTSignature alloc] initWithSignature:theSignature] autorelease];
}
- (id)initWithSignature:(git_signature *)theSignature {
	
	if(self = [self init]) {
		self.signature = theSignature;
	}
	return self;
}

+ (id)signatureWithName:(NSString *)theName email:(NSString *)theEmail time:(NSDate *)theTime {
	
	return [[[GTSignature alloc] initWithName:theName email:theEmail time:theTime] autorelease];
}
- (id)initWithName:(NSString *)theName email:(NSString *)theEmail time:(NSDate *)theTime {
	
	if(self = [super init]) {
		self.signature = git_signature_new(
										   [NSString utf8StringForString:theName], 
										   [NSString utf8StringForString:theEmail], 
										   [theTime timeIntervalSince1970], 
										   0);
		// tclem todo: figure out offset for NSDate
	}
	return self;
}

- (NSString *)name {
	
	return [NSString stringForUTF8String:self.signature->name];
}
- (void)setName:(NSString *)n {
	
	free(self.signature->name);
	self.signature->name = strdup([n cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (NSString *)email {
	
	return [NSString stringForUTF8String:self.signature->email];
}
- (void)setEmail:(NSString *)e {
	
	free(self.signature->email);
	self.signature->email = strdup([e cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (NSDate *)time {
	
	return [NSDate dateWithTimeIntervalSince1970:self.signature->when.time];
}
- (void)setTime:(NSDate *)d {
	
	self.signature->when.time = [d timeIntervalSince1970];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"\
			\n\t %@						\
			\n\t name = %@				\
			\n\t email = %@				\
			\n\t time = %@				\
			",
			NSStringFromClass([self class]),
			self.name,
			self.email,
			self.time
			];
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	
	// if i free the signature, writes fails
	//git_signature_free(self.signature);
	
	// All these properties pass through to underlying C object
	// there is nothing to release here
	//self.name = nil;
	//self.email = nil;
	//self.time = nil;
	[super dealloc];
}

@end
