//
//  GTDiffDelta.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffDelta.h"

#import "GTBlob.h"
#import "GTDiff+Private.h"
#import "GTDiffFile.h"
#import "GTDiffPatch.h"
#import "NSError+Git.h"

@interface GTDiffDelta ()

/// Used to generate a patch from this delta.
@property (nonatomic, copy, readonly) int (^patchGenerator)(git_patch **patch);

@end

@implementation GTDiffDelta

#pragma mark Properties

- (GTDiffFileFlag)flags {
	return (GTDiffFileFlag)self.git_diff_delta.flags;
}

- (GTDiffFile *)oldFile {
	return [[GTDiffFile alloc] initWithGitDiffFile:self.git_diff_delta.old_file];
}

- (GTDiffFile *)newFile {
	return [[GTDiffFile alloc] initWithGitDiffFile:self.git_diff_delta.new_file];
}

- (GTDiffDeltaType)type {
	return (GTDiffDeltaType)self.git_diff_delta.status;
}

#pragma mark Lifecycle

static int GTDiffDeltaCallback(const git_diff_delta *delta, float progress, void *payload) {
	git_diff_delta *storage = payload;
	*storage = *delta;

	return GIT_OK;
}

+ (instancetype)diffDeltaFromBlob:(GTBlob *)blob forPath:(NSString *)blobPath toData:(NSData *)data forPath:(NSString *)dataPath options:(NSDictionary *)options error:(NSError **)error {
	__block git_diff_delta diffDelta;

	int returnValue = [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_blob_to_buffer(blob.git_blob, blobPath.fileSystemRepresentation, data.bytes, data.length, dataPath.fileSystemRepresentation, optionsStruct, &GTDiffDeltaCallback, NULL, NULL, &diffDelta);
	}];

	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create diff delta between blob %@ at path %@ and data at path %@", blob.SHA, blobPath, dataPath];
		return nil;
	}
	
	return [[self alloc] initWithGitDiffDelta:diffDelta patchGeneratorBlock:^(git_patch **patch) {
		return [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
			return git_patch_from_blob_and_buffer(patch, blob.git_blob, blobPath.fileSystemRepresentation, data.bytes, data.length, dataPath.fileSystemRepresentation, optionsStruct);
		}];
	}];
}

+ (instancetype)diffDeltaFromData:(NSData *)oldData forPath:(NSString *)oldDataPath toData:(NSData *)newData forPath:(NSString *)newDataPath options:(NSDictionary *)options error:(NSError **)error {
	__block git_diff_delta diffDelta;

	int returnValue = [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_buffers(oldData.bytes, oldData.length, oldDataPath.fileSystemRepresentation, newData.bytes, newData.length, newDataPath.fileSystemRepresentation, optionsStruct, &GTDiffDeltaCallback, NULL, NULL, &diffDelta);
	}];

	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create diff delta between data at path %@ and data at path %@", oldDataPath, newDataPath];
		return nil;
	}
	
	return [[self alloc] initWithGitDiffDelta:diffDelta patchGeneratorBlock:^(git_patch **patch) {
		return [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
			return git_patch_from_buffers(patch, oldData.bytes, oldData.length, oldDataPath.fileSystemRepresentation, newData.bytes, newData.length, newDataPath.fileSystemRepresentation, optionsStruct);
		}];
	}];
}

- (instancetype)initWithDiff:(GTDiff *)diff deltaIndex:(NSUInteger)deltaIndex {
	NSCParameterAssert(diff != nil);

	git_diff_delta delta = *(git_diff_get_delta(diff.git_diff, deltaIndex));
	return [self initWithGitDiffDelta:delta patchGeneratorBlock:^(git_patch **patch) {
		return git_patch_from_diff(patch, diff.git_diff, deltaIndex);
	}];
}

- (instancetype)initWithGitDiffDelta:(git_diff_delta)diffDelta patchGeneratorBlock:(int (^)(git_patch **patch))patchGenerator {
	NSCParameterAssert(patchGenerator != nil);

	self = [super init];
	if (self == nil) return nil;

	_git_diff_delta = diffDelta;
	_patchGenerator = [patchGenerator copy];

	return self;
}

#pragma mark Patch Generation

- (GTDiffPatch *)generatePatch:(NSError **)error {
	git_patch *patch = NULL;
	int gitError = self.patchGenerator(&patch);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Patch generation failed for delta %@", self];
		return nil;
	}

	return [[GTDiffPatch alloc] initWithGitPatch:patch delta:self];
}

#pragma mark NSObject

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p>{ flags: %u, oldFile: %@, newFile: %@ }", self.class, self, (unsigned)self.git_diff_delta.flags, self.oldFile, self.newFile];
}

@end
