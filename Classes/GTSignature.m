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


@implementation GTSignature

- (NSString *)description {
	
	return [NSString stringWithFormat:@"<%@: %p> name: %@, email: %@, time: %@", NSStringFromClass([self class]), self, self.name, self.email, self.time];
}

#pragma mark -
#pragma mark API 

@synthesize sig;
@synthesize name;
@synthesize email;
@synthesize time;

- (id)initWithSig:(git_signature *)theSignature {
	
	if((self = [self init])) {
		self.sig = theSignature;
	}
	return self;
}
+ (id)signatureWithSig:(git_signature *)theSignature {
	
	return [[[self alloc] initWithSig:theSignature] autorelease];
}

- (id)initWithName:(NSString *)theName email:(NSString *)theEmail time:(NSDate *)theTime {
	
	if((self = [super init])) {
		self.sig = git_signature_new(
										   [theName UTF8String], 
										   [theEmail UTF8String], 
										   [theTime timeIntervalSince1970], 
										   0);
		// todo: figure out offset for NSDate
	}
	return self;
}
+ (id)signatureWithName:(NSString *)theName email:(NSString *)theEmail time:(NSDate *)theTime {
	
	return [[[self alloc] initWithName:theName email:theEmail time:theTime] autorelease];
}

- (NSString *)name {
	
	return [NSString stringWithUTF8String:self.sig->name];
}
- (void)setName:(NSString *)n {
	
	free(self.sig->name);
	self.sig->name = strdup([n cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (NSString *)email {
	
	return [NSString stringWithUTF8String:self.sig->email];
}
- (void)setEmail:(NSString *)e {
	
	free(self.sig->email);
	self.sig->email = strdup([e cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (NSDate *)time {
	
	return [NSDate dateWithTimeIntervalSince1970:self.sig->when.time];
}
- (void)setTime:(NSDate *)d {
	
	self.sig->when.time = [d timeIntervalSince1970];
}

@end
