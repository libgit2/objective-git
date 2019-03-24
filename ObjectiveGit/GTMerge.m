//
//  GTMergeFile.m
//  ObjectiveGitFramework
//
//  Created by Etienne on 26/10/2018.
//  Copyright © 2018 GitHub, Inc. All rights reserved.
//

#import "GTMerge.h"
#import "NSError+Git.h"

@interface GTMergeResult ()

@property (assign) git_merge_file_result result;

@end

@implementation GTMergeResult

- (instancetype)initWithGitMergeFileResult:(git_merge_file_result *)result {
	self = [super init];
	if (!self) return nil;

	memcpy(&_result, result, sizeof(_result));

	return self;
}

- (void)dealloc {
	git_merge_file_result_free(&_result);
}

- (BOOL)isAutomergeable {
	return !!_result.automergeable;
}

- (NSString *)path {
	return (_result.path ? [NSString stringWithUTF8String:_result.path] : nil);
}

- (unsigned int)mode {
	return _result.mode;
}

- (NSData *)data {
	return [[NSData alloc] initWithBytesNoCopy:(void *)_result.ptr length:_result.len freeWhenDone:NO];
}

@end

@interface GTMergeFile ()

@property (copy) NSData *data;
@property (copy) NSString *path;
@property (assign) unsigned int mode;
@property (assign) git_merge_file_input file;

@end

@implementation GTMergeFile

+ (instancetype)fileWithString:(NSString *)string path:(NSString * _Nullable)path mode:(unsigned int)mode {
	NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];

	NSAssert(stringData != nil, @"String couldn't be converted to UTF-8");

	return [[self alloc] initWithData:stringData path:path mode:mode];
}

- (instancetype)initWithData:(NSData *)data path:(NSString *)path mode:(unsigned int)mode {
	NSParameterAssert(data);
	self = [super init];
	if (!self) return nil;

	_data = data;
	_path = path;
	_mode = mode;

	git_merge_file_init_input(&_file, GIT_MERGE_FILE_INPUT_VERSION);

	_file.ptr = self.data.bytes;
	_file.size = self.data.length;
	_file.path = [self.path UTF8String];
	_file.mode = self.mode;

	return self;
}

- (git_merge_file_input *)git_merge_file_input {
	return &_file;
}

+ (BOOL)handleMergeFileOptions:(git_merge_file_options *)opts optionsDict:(NSDictionary *)dict error:(NSError **)error {
	NSParameterAssert(opts);

	int gitError = git_merge_file_init_options(opts, GIT_MERGE_FILE_OPTIONS_VERSION);
	if (gitError != 0) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Invalid option initialization"];
		return NO;
	}

	if (dict.count != 0) {
		if (error) *error = [NSError git_errorFor:-1 description:@"No options handled"];
		return NO;
	}
	return YES;
}

+ (GTMergeResult *)performMergeWithAncestor:(GTMergeFile *)ancestorFile ourFile:(GTMergeFile *)ourFile theirFile:(GTMergeFile *)theirFile options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(ourFile);
	NSParameterAssert(theirFile);
	NSParameterAssert(ancestorFile);

	git_merge_file_result gitResult;
	git_merge_file_options opts;

	BOOL success = [GTMergeFile handleMergeFileOptions:&opts optionsDict:options error:error];
	if (!success) return nil;

	int gitError = git_merge_file(&gitResult, ancestorFile.git_merge_file_input, ourFile.git_merge_file_input, theirFile.git_merge_file_input, &opts);
	if (gitError != 0) {
		if (error) *error = [NSError git_errorFor:gitError description:@"Merge file failed"];
		return nil;
	}

	return [[GTMergeResult alloc] initWithGitMergeFileResult:&gitResult];
}

@end
