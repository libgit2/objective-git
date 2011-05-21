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

- (git_blob *)blob {
	
	return (git_blob *)self.obj;
}

#pragma mark -
#pragma mark API

+ (GTBlob *)blobInRepository:(GTRepository *)theRepo content:(NSString *)content error:(NSError **)error {
	
	NSString *sha = [GTBlob shaByCreatingBlobInRepository:theRepo content:content error:error];
	return sha ? (GTBlob *)[theRepo lookupObjectBySha:sha objectType:GTObjectTypeBlob error:error] : nil;
}

+ (GTBlob *)blobInRepository:(GTRepository *)theRepo data:(NSData *)data error:(NSError **)error {
	
	NSString *sha = [GTBlob shaByCreatingBlobInRepository:theRepo data:data error:error];
	return sha ? (GTBlob *)[theRepo lookupObjectBySha:sha objectType:GTObjectTypeBlob error:error] : nil;
}

+ (GTBlob *)blobInRepository:(GTRepository *)theRepo file:(NSURL *)file error:(NSError **)error {
	
	NSString *sha = [GTBlob shaByCreatingBlobInRepository:theRepo file:file error:error];
	return sha ? (GTBlob *)[theRepo lookupObjectBySha:sha objectType:GTObjectTypeBlob error:error] : nil;
}

+ (NSString *)shaByCreatingBlobInRepository:(GTRepository *)theRepo content:(NSString *)content error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_blob_create_frombuffer(&oid, theRepo.repo, [content UTF8String], content.length);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to create blob from NSString"];
		return nil;
	}
	
	return [NSString git_stringWithOid:&oid];
}

+ (NSString *)shaByCreatingBlobInRepository:(GTRepository *)theRepo data:(NSData *)data error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_blob_create_frombuffer(&oid, theRepo.repo, [data bytes], data.length);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to create blob from NSData"];
		return nil;
	}
	
	return [NSString git_stringWithOid:&oid];
}

+ (NSString *)shaByCreatingBlobInRepository:(GTRepository *)theRepo file:(NSURL *)file error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_blob_create_fromfile(&oid, theRepo.repo, [[file path] UTF8String]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to create blob from NSURL"];
		return nil;
	}
	
	return [NSString git_stringWithOid:&oid];
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
