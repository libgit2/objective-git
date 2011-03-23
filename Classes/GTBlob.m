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
#import "NSString+Git.h"
#import "NSError+Git.h"
#import "GTRepository.h"
#import "GTLib.h"


@implementation GTBlob

- (git_blob *)blob {
	
	return (git_blob *)self.object;
}

#pragma mark -
#pragma mark API

//@synthesize size;
//@synthesize content;

/*
- (id)initInRepo:(GTRepository *)theRepo content:(NSString *)newContent error:(NSError **)error {
	
	if((self = [super init])) {
		git_oid oid;
		
		self.repo = theRepo;
		
		int gitError = git_blob_create_frombuffer(&oid, self.repo.repo, [NSString utf8StringForString:newContent], newContent.length);
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorFor:gitError withDescription:@"Failed to create blob from buffer"];
			return nil;
		}
		
		self.object = [self.repo lookupByOid:&oid error:error];
		if(self.object == nil)return nil;
	}
	return self;
}
*/

+ (NSString *)createInRepo:(GTRepository *)theRepo content:(NSString *)content error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_blob_create_frombuffer(&oid, theRepo.repo, [NSString utf8StringForString:content], content.length);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to create blob from NSString"];
		return nil;
	}
	
	return [GTLib convertOidToSha:&oid];
}

+ (NSString *)createInRepo:(GTRepository *)theRepo data:(NSData *)data error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_blob_create_frombuffer(&oid, theRepo.repo, [data bytes], data.length);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to create blob from NSData"];
		return nil;
	}
	
	return [GTLib convertOidToSha:&oid];
}

+ (NSString *)createInRepo:(GTRepository *)theRepo file:(NSURL *)file error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_blob_create_fromfile(&oid, theRepo.repo, [NSString utf8StringForString:[file path]]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to create blob from NSURL"];
		return nil;
	}
	
	return [GTLib convertOidToSha:&oid];
}

- (NSInteger)size {
	
	return git_blob_rawsize(self.blob);
}

- (NSString *)content {
	
	NSInteger s = [self size];
	if(s == 0) return @"";
	
	return [NSString stringForUTF8String:git_blob_rawcontent(self.blob)];
}
/*
- (void)setContent:(NSString *)newContent {
	
	git_blob_set_rawcontent(self.blob, [NSString utf8StringForString:newContent], [newContent length]);
}
*/
@end
