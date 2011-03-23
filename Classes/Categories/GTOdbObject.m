//
//  GTOdbObject.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/23/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import "GTOdbObject.h"
#import "GTLib.h"
#import "NSString+Git.h"

@interface GTOdbObject()
@property (nonatomic, assign) git_odb_object *odbObject;
@end

@implementation GTOdbObject

#pragma mark API
@synthesize odbObject;

- (id)initWithObject:(git_odb_object *)object {
	
	if((self = [super init])) {
		self.odbObject = object;
	}
	return self;
}

+ (id)objectWithObject:(git_odb_object *)object {
	
	return [[[self alloc] initWithObject:object] autorelease];
}

- (NSString *)hash {
	
	return [GTLib convertOidToSha:git_odb_object_id(self.odbObject)];
}

- (GTObjectType)type {

	return git_odb_object_type(self.odbObject);
	//return [NSString stringForUTF8String:git_object_type2string(git_odb_object_type(self.odbObject))];
}

- (NSUInteger)length {
	
	return git_odb_object_size(self.odbObject);
}

- (NSData *)data {
	
	return [NSData dataWithBytes:git_odb_object_data(self.odbObject) length:[self length]]; 
}

- (NSString *)dataAsUTF8String {
	
	NSData *data = [self data];
	if(!data) return nil;
	
	return [NSString stringWithUTF8String:[data bytes]];
}

@end
