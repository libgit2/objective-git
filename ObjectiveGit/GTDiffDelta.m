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

/// Used to dynamically access the underlying `git_diff_delta`.
@property (nonatomic, copy, readonly) git_diff_delta (^deltaAccessor)(void);

/// Used to generate a patch from this delta.
@property (nonatomic, copy, readonly) int (^patchGenerator)(git_patch **patch);

/// Initializes the diff delta with blocks that will fulfill its contract.
///
/// deltaAccessor  - A block that will return the `git_diff_delta` underlying
///                  this object. Must not be nil.
/// patchGenerator - A block that will be used to lazily generate a patch for
///                  the given diff delta. Must not be nil.
///
/// This is the designated initializer for this class.
- (instancetype)initWithGitDiffDeltaBlock:(git_diff_delta (^)(void))deltaAccessor patchGeneratorBlock:(int (^)(git_patch **patch))patchGenerator;

@end

@implementation GTDiffDelta

#pragma mark Properties

- (git_diff_delta)git_diff_delta {
	return self.deltaAccessor();
}

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

+ (instancetype)diffDeltaFromBlob:(GTBlob *)oldBlob forPath:(NSString *)oldBlobPath toBlob:(GTBlob *)newBlob forPath:(NSString *)newBlobPath options:(NSDictionary *)options error:(NSError **)error {
	__block git_diff_delta diffDelta;

	int returnValue = [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_blobs(oldBlob.git_blob, oldBlobPath.UTF8String, newBlob.git_blob, newBlobPath.UTF8String, optionsStruct, &GTDiffDeltaCallback, NULL, NULL, &diffDelta);
	}];

	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create diff delta between blob %@ at path %@ and blob %@ at path %@", oldBlob.SHA, oldBlobPath, newBlob.SHA, newBlobPath];
		return nil;
	}
	
	return [[self alloc] initWithGitDiffDeltaBlock:^{
		return diffDelta;
	} patchGeneratorBlock:^(git_patch **patch) {
		return [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
			return git_patch_from_blobs(patch, oldBlob.git_blob, oldBlobPath.UTF8String, newBlob.git_blob, newBlobPath.UTF8String, optionsStruct);
		}];
	}];
}

+ (instancetype)diffDeltaFromBlob:(GTBlob *)blob forPath:(NSString *)blobPath toData:(NSData *)data forPath:(NSString *)dataPath options:(NSDictionary *)options error:(NSError **)error {
	__block git_diff_delta diffDelta;

	int returnValue = [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_blob_to_buffer(blob.git_blob, blobPath.UTF8String, data.bytes, data.length, dataPath.UTF8String, optionsStruct, &GTDiffDeltaCallback, NULL, NULL, &diffDelta);
	}];

	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create diff delta between blob %@ at path %@ and data at path %@", blob.SHA, blobPath, dataPath];
		return nil;
	}
	
	return [[self alloc] initWithGitDiffDeltaBlock:^{
		return diffDelta;
	} patchGeneratorBlock:^(git_patch **patch) {
		return [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
			return git_patch_from_blob_and_buffer(patch, blob.git_blob, blobPath.UTF8String, data.bytes, data.length, dataPath.UTF8String, optionsStruct);
		}];
	}];
}

+ (instancetype)diffDeltaFromData:(NSData *)oldData forPath:(NSString *)oldDataPath toData:(NSData *)newData forPath:(NSString *)newDataPath options:(NSDictionary *)options error:(NSError **)error {
	__block git_diff_delta diffDelta;

	int returnValue = [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
		return git_diff_buffers(oldData.bytes, oldData.length, oldDataPath.UTF8String, newData.bytes, newData.length, newDataPath.UTF8String, optionsStruct, &GTDiffDeltaCallback, NULL, NULL, &diffDelta);
	}];

	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create diff delta between data at path %@ and data at path %@", oldDataPath, newDataPath];
		return nil;
	}
	
	return [[self alloc] initWithGitDiffDeltaBlock:^{
		return diffDelta;
	} patchGeneratorBlock:^(git_patch **patch) {
		return [GTDiff handleParsedOptionsDictionary:options usingBlock:^(git_diff_options *optionsStruct) {
			return git_patch_from_buffers(patch, oldData.bytes, oldData.length, oldDataPath.UTF8String, newData.bytes, newData.length, newDataPath.UTF8String, optionsStruct);
		}];
	}];
}

- (instancetype)initWithDiff:(GTDiff *)diff deltaIndex:(NSUInteger)deltaIndex {
	NSCParameterAssert(diff != nil);

	return [self initWithGitDiffDeltaBlock:^{
		return *(git_diff_get_delta(diff.git_diff, deltaIndex));
	} patchGeneratorBlock:^(git_patch **patch) {
		return git_patch_from_diff(patch, diff.git_diff, deltaIndex);
	}];
}

- (instancetype)initWithGitDiffDeltaBlock:(git_diff_delta (^)(void))deltaAccessor patchGeneratorBlock:(int (^)(git_patch **patch))patchGenerator {
	NSCParameterAssert(deltaAccessor != nil);
	NSCParameterAssert(patchGenerator != nil);

	self = [super init];
	if (self == nil) return nil;

	_deltaAccessor = [deltaAccessor copy];
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
