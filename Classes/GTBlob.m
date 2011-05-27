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
#import "NSError+Git.h"
#import "GTRepository.h"
#import "NSString+Git.h"


@implementation GTBlob
- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> size: %i, content: %@, data = %@", NSStringFromClass([self class]), self, [self size], [self content], [self data]];
}

- (git_blob *)blob {
	
	return (git_blob *)self.obj;
}

#pragma mark -
#pragma mark API

+ (id)blobWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError **)error {
    
	return [[[self alloc] initWithString:string inRepository:repository error:error] autorelease];
}

+ (id)blobWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError **)error {
    
	return [[[self alloc] initWithData:data inRepository:repository error:error] autorelease];
}

+ (id)blobWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError **)error {
    
	return [[[self alloc] initWithFile:file inRepository:repository error:error] autorelease];
}

- (id)initWithOid:(const git_oid *)oid inRepository:(GTRepository *)repository error:(NSError **)error {
    
	git_object *obj;
    int gitError = git_object_lookup(&obj, repository.repo, oid, GTObjectTypeBlob);
    if (gitError < GIT_SUCCESS) {
        if (error != NULL) {
            *error = [NSError git_errorFor:gitError withDescription:@"Failed to lookup blob"];
        }
        [self release];
        return nil;
    }
	
    return [self initWithObj:obj inRepository:repository];
}

- (id)initWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError **)error {
    
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self initWithData:data inRepository:repository error:error];
}

- (id)initWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError **)error {
    
	git_oid oid;
	int gitError = git_blob_create_frombuffer(&oid, repository.repo, [data bytes], data.length);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL) {
			*error = [NSError git_errorFor:gitError withDescription:@"Failed to create blob from NSData"];
        }
        [self release];
		return nil;
	}
    
    return [self initWithOid:&oid inRepository:repository error:error];
}

- (id)initWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_blob_create_fromfile(&oid, repository.repo, [[file path] UTF8String]);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL) {
			*error = [NSError git_errorFor:gitError withDescription:@"Failed to create blob from NSURL"];
        }
        [self release];
		return nil;
	}
	
    return [self initWithOid:&oid inRepository:repository error:error];
}

- (NSInteger)size {
	
	return git_blob_rawsize(self.blob);
}

- (NSString *)content {
	
	NSInteger s = [self size];
	if(s == 0) return @"";
	
	return [NSString stringWithUTF8String:git_blob_rawcontent(self.blob)];
}

- (NSData *)data {
    
	NSInteger s = [self size];
    if (s == 0) return [NSData data];
    
    return [NSData dataWithBytes:git_blob_rawcontent(self.blob) length:s];
}

@end
