//
//  GTOdbObject.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/23/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import "GTOdbObject.h"
#import "NSString+Git.h"

@interface GTOdbObject()
@property (nonatomic, assign) git_odb_object *odbObject;
@end

@implementation GTOdbObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> shaHash: %@, length: %i, data: %@", NSStringFromClass([self class]), self, [self shaHash], [self length], [self data]];
}

#pragma mark -
#pragma mark API

@synthesize odbObject;

- (id)initWithOdbObj:(git_odb_object *)object {
	
	if((self = [super init])) {
		self.odbObject = object;
	}
	return self;
}

+ (id)objectWithOdbObj:(git_odb_object *)object {
	
	return [[[self alloc] initWithOdbObj:object] autorelease];
}

- (NSString *)shaHash {
	
	return [NSString git_stringWithOid:git_odb_object_id(self.odbObject)];
}

- (GTObjectType)type {

	return (GTObjectType) git_odb_object_type(self.odbObject);
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
