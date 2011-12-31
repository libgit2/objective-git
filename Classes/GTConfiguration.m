//
//  GTConfiguration.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 12/30/11.
//  Copyright (c) 2011 GitHub, Inc. All rights reserved.
//

#import "GTConfiguration.h"

@interface GTConfiguration ()
@property (nonatomic, assign) git_config *git_config;
@end


@implementation GTConfiguration

- (void)dealloc {
	git_config_free(self.git_config);
}


#pragma mark API

@synthesize git_config;

+ (GTConfiguration *)configurationWithConfiguration:(git_config *)config {
	GTConfiguration *configuration = [[self alloc] init];
	configuration.git_config = config;
	return configuration;
}

- (void)setString:(NSString *)s forKey:(NSString *)key {
	git_config_set_string(self.git_config, [key UTF8String], [s UTF8String]);
}

- (NSString *)stringForKey:(NSString *)key {
	const char *string = NULL;
	git_config_get_string(self.git_config, [key UTF8String], &string);
	if(string == NULL) return nil;
	
	return [NSString stringWithUTF8String:string];
}

- (void)setBoolForKey:(BOOL)b forKey:(NSString *)key {
	git_config_set_bool(self.git_config, [key UTF8String], b);
}

- (BOOL)boolForKey:(NSString *)key {
	int b = 0;
	git_config_get_bool(self.git_config, [key UTF8String], &b);
	return (BOOL) b;
}

- (void)setInt32:(int32_t)i forKey:(NSString *)key {
	git_config_set_int32(self.git_config, [key UTF8String], i);
}

- (int32_t)int32ForKey:(NSString *)key {
	int32_t i = 0;
	git_config_get_int32(self.git_config, [key UTF8String], &i);
	
	return i;
}

- (void)setInt64:(int64_t)i forKey:(NSString *)key {
	git_config_set_int64(self.git_config, [key UTF8String], i);
}

- (int64_t)int64ForKey:(NSString *)key {
	int64_t i = 0;
	git_config_get_int64(self.git_config, [key UTF8String], &i);
	
	return i;
}

- (BOOL)deleteValueForKey:(NSString *)key error:(NSError **)error {
	git_config_delete(self.git_config, [key UTF8String]);

	return YES;
}

@end
