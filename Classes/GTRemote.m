//
//  GTRemote.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTRemote.h"
#import "NSError+Git.h"

@interface GTRemote ()

@property (nonatomic, readonly, assign) git_remote *git_remote;

@end

@implementation GTRemote

#pragma mark Lifecycle

- (id)initWithGitRemote:(git_remote *)remote {
	NSParameterAssert(remote != NULL);

	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;

	return self;
}

- (void)dealloc {
	if (_git_remote != NULL) git_remote_free(_git_remote);
}

#pragma mark NSObject

- (BOOL)isEqual:(GTRemote *)object {
	if (object == self) return YES;
	if (![object isKindOfClass:[self class]]) return NO;

	return [object.name isEqual:self.name] && [object.URLString isEqual:self.URLString];
}

- (NSUInteger)hash {
	return self.name.hash ^ self.URLString.hash;
}

#pragma mark Properties

- (NSString *)name {
	const char *name = git_remote_name(self.git_remote);
	if (name == NULL) return nil;

	return @(name);
}

- (NSString *)URLString {
	const char *URLString = git_remote_url(self.git_remote);
	if (URLString == NULL) return nil;

	return @(URLString);
}

- (NSArray *)fetchRefSpecs {
	git_strarray refSpecs;
	int gitError = git_remote_get_fetch_refspecs(&refSpecs, self.git_remote);
	if (gitError != GIT_OK) return nil;

	NSMutableArray *fetchRefSpecs = [NSMutableArray arrayWithCapacity:refSpecs.count];
	for (size_t i = 0; i < refSpecs.count; i++) {
		if (refSpecs.strings[i] == NULL) continue;
		[fetchRefSpecs addObject:@(refSpecs.strings[i])];
	}
	git_strarray_free(&refSpecs);

	return [fetchRefSpecs copy];
}

#pragma Update the remote

- (BOOL)saveRemote:(NSError **)error {
	int gitError = git_remote_save(self.git_remote);

	BOOL success = (gitError == GIT_OK);
	if (!success) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to save remote configuration."];
		}
	}
	return success;
}

- (BOOL)updateURLString:(NSString *)URLString error:(NSError **)error {
	if ([self.URLString isEqualToString:URLString]) return YES;

	int gitError = git_remote_set_url(self.git_remote, (URLString == nil ? "" : URLString.UTF8String));

	BOOL success = (gitError == GIT_OK);
	if (!success) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to update remote URL string."];
		}
		return success;
	}
	return [self saveRemote:error];
}

- (BOOL)addFetchRefSpec:(NSString *)fetchRefSpec error:(NSError **)error {
	NSParameterAssert(fetchRefSpec != nil);

	if ([self.fetchRefSpecs containsObject:fetchRefSpec]) return YES;

	int gitError = git_remote_add_fetch(self.git_remote, fetchRefSpec.UTF8String);

	BOOL success = (gitError == GIT_OK);
	if (!success) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to add fetch refspec."];
		}
		return success;
	}
	return [self saveRemote:error];
}

- (BOOL)removeFetchRefSpec:(NSString *)fetchRefSpec error:(NSError **)error {
	NSUInteger index = [self.fetchRefSpecs indexOfObject:fetchRefSpec];
	if (index == NSNotFound) return YES;

	int gitError = git_remote_remove_refspec(self.git_remote, index);
	BOOL success = (gitError == GIT_OK);
	if (!success) {
		if (error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Unable to remove fetch refspec."];
		}
		return success;
	}
	return [self saveRemote:error];
}

@end
