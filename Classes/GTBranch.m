//
//  GTBranch.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/3/11.
//  Copyright 2011 GitHub, Inc. All rights reserved.
//

#import "GTBranch.h"
#import "GTReference.h"
#import "GTLib.h"
#import "GTWalker.h"

@interface GTBranch ()
@property (nonatomic, retain) GTReference *reference;
@property (nonatomic, retain) GTRepository *repository;

+ (NSString *)defaultBranchRefPath;
@end


@implementation GTBranch

- (void)dealloc {
	self.reference = nil;
	self.repository = nil;
	
	[super dealloc];
}


#pragma mark API

@synthesize reference;
@synthesize repository;

+ (NSString *)defaultBranchRefPath {
	return @"refs/heads/";
}

- (id)initWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error {
	self = [super init];
	if(self == nil) return nil;
	
	self.reference = [GTReference referenceByLookingUpRef:[NSString stringWithFormat:@"%@%@", [[self class] defaultBranchRefPath], branchName] inRepo:repo error:error];
	if(self.reference == nil) return nil;
	
	self.repository = repo;
	
	return self;
}

- (NSString *)name {
	return [self.reference.name stringByReplacingOccurrencesOfString:[[self class] defaultBranchRefPath] withString:@""];
}

- (GTWalker *)walkerWithOptions:(GTWalkerOptions)options error:(NSError **)error {
	GTWalker *walker = [[GTWalker alloc] initWithRepository:self.repository error:error];
	[walker setSortingOptions:options];
	[walker push:[GTLib hexFromOid:self.reference.oid] error:error];
	return walker;
}

@end
