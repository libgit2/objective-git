//
//  GTSignature.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
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


- (void)finalize {
	
	git_signature_free(signature);
	[super finalize];
}


@end
