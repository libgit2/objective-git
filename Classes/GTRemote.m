//
//  GTRemote.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 9/12/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTRemote.h"

@interface GTRemote ()
@property (nonatomic, readonly, assign) git_remote *git_remote;
@end

@implementation GTRemote

- (void)dealloc {
	if (_git_remote != NULL) git_remote_free(_git_remote);
}

- (BOOL)isEqual:(GTRemote *)object {
	if (object == self) return YES;
	if (![object isKindOfClass:[self class]]) return NO;

	return [object.name isEqual:self.name] && [object.URLString isEqual:self.URLString];
}

- (NSUInteger)hash {
	return self.name.hash ^ self.URLString.hash;
}

#pragma mark API

- (id)initWithGitRemote:(git_remote *)remote {
	self = [super init];
	if (self == nil) return nil;

	_git_remote = remote;

	return self;
}

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

@end
