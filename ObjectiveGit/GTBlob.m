//
//  GTBlob.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/25/11.
//
//  The MIT License
//
//  Copyright (c) 2011 Tim Clem
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "GTBlob.h"

#import "GTRepository.h"
#import "NSData+Git.h"
#import "NSError+Git.h"
#import "NSString+Git.h"

#import "git2/blob.h"
#import "git2/errors.h"

@implementation GTBlob

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> size: %lli, content: %@, data = %@", NSStringFromClass([self class]), self, [self size], [self content], [self data]];
}


#pragma mark API

+ (instancetype)blobWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError **)error {
	return [[self alloc] initWithString:string inRepository:repository error:error];
}

+ (instancetype)blobWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError **)error {
	return [[self alloc] initWithData:data inRepository:repository error:error];
}

+ (instancetype)blobWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError **)error {
	return [[self alloc] initWithFile:file inRepository:repository error:error];
}

- (instancetype)initWithOid:(const git_oid *)oid inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(oid != NULL);
	NSParameterAssert(repository != nil);

	git_object *obj;
    int gitError = git_object_lookup(&obj, repository.git_repository, oid, (git_object_t) GTObjectTypeBlob);
    if (gitError < GIT_OK) {
        if (error != NULL) {
            *error = [NSError git_errorFor:gitError description:@"Failed to lookup blob"];
        }
        return nil;
    }
	
    return [self initWithObj:obj inRepository:repository];
}

- (instancetype)initWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError **)error {
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self initWithData:data inRepository:repository error:error];
}

- (instancetype)initWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(data != nil);
	NSParameterAssert(repository != nil);

	git_oid oid;
	int gitError = git_blob_create_from_buffer(&oid, repository.git_repository, [data bytes], data.length);
	if(gitError < GIT_OK) {
		if(error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to create blob from NSData"];
        }
		return nil;
	}
    
    return [self initWithOid:&oid inRepository:repository error:error];
}

- (instancetype)initWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError **)error {
	NSParameterAssert(file != nil);
	NSParameterAssert(repository != nil);

	git_oid oid;
	int gitError = git_blob_create_from_disk(&oid, repository.git_repository, [[file path] fileSystemRepresentation]);
	if(gitError < GIT_OK) {
		if(error != NULL) {
			*error = [NSError git_errorFor:gitError description:@"Failed to create blob from NSURL"];
        }
		return nil;
	}
	
    return [self initWithOid:&oid inRepository:repository error:error];
}

- (git_blob *)git_blob {	
	return (git_blob *) self.git_object;
}

- (git_off_t)size {
	return git_blob_rawsize(self.git_blob);
}

- (NSString *)content {
	git_off_t s = [self size];
	if(s <= 0) return @"";
	
	return [NSString stringWithUTF8String:git_blob_rawcontent(self.git_blob)];
}

- (NSData *)data {
	git_off_t s = [self size];
    if (s <= 0) return [NSData data];
    
    return [NSData dataWithBytes:git_blob_rawcontent(self.git_blob) length:(NSUInteger)s];
}

- (NSData *)applyFiltersForPath:(NSString *)path error:(NSError **)error {
	NSCParameterAssert(path != nil);

	git_buf buffer = GIT_BUF_INIT_CONST(0, NULL);

	git_blob_filter_options opts = GIT_BLOB_FILTER_OPTIONS_INIT;
	int gitError = git_blob_filter(&buffer, self.git_blob, path.UTF8String, &opts);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to apply filters for path %@ to blob", path];
		return nil;
	}

	return [NSData git_dataWithBuffer:&buffer];
}

@end
