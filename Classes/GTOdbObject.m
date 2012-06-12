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
@property (nonatomic, assign) git_odb_object *git_odb_object;
@end


@implementation GTOdbObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> shaHash: %@, length: %zi, data: %@", NSStringFromClass([self class]), self, [self shaHash], [self length], [self data]];
}


#pragma mark API

@synthesize git_odb_object;

- (id)initWithOdbObj:(git_odb_object *)object {
	if((self = [super init])) {
		self.git_odb_object = object;
	}
	return self;
}

+ (id)objectWithOdbObj:(git_odb_object *)object {
	return [[self alloc] initWithOdbObj:object];
}

- (NSString *)shaHash {
	return [NSString git_stringWithOid:git_odb_object_id(self.git_odb_object)];
}

- (GTObjectType)type {
	return (GTObjectType) git_odb_object_type(self.git_odb_object);
}

- (size_t)length {
	return git_odb_object_size(self.git_odb_object);
}

- (NSData *)data {
	return [NSData dataWithBytes:git_odb_object_data(self.git_odb_object) length:[self length]]; 
}

@end
