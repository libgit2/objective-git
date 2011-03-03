//
//  GTRepository.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/17/11.
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

#import "GTRepository.h"
#import "GTWalker.h"
#import "GTObject.h"
#import "GTCommit.h"
#import "GTRawObject.h"
#import "GTLib.h"
#import "GTIndex.h"
#import "NSError+Git.h"
#import "NSString+Git.h"


@interface GTRepository ()
@end


@implementation GTRepository

@synthesize repo;
@synthesize fileUrl;
@synthesize walker;
@synthesize index;

+ (id)repoByOpeningRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error {
	return [[[GTRepository alloc]initByOpeningRepositoryInDirectory:localFileUrl error:error] autorelease];
}

+ (id)repoByCreatingRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error {
	return [[[GTRepository alloc]initByCreatingRepositoryInDirectory:localFileUrl error:error] autorelease];
}

- (id)initByOpeningRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error {
	
	if(self = [super init]){
		
		self.fileUrl = localFileUrl;
		
		GTLog("Opening repository in directory: %@", localFileUrl);
		
		const char *path;
		if([[localFileUrl path] hasSuffix:@".git"]) {
			path = [NSString utf8StringForString:[localFileUrl path]];
		} else {
			path = [NSString utf8StringForString:[NSString stringWithFormat:@"%@/.git", [localFileUrl path]]];
		}
		
		git_repository *r;
		int gitError = git_repository_open(&r, path);
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorForOpenRepository:gitError];
			return nil;
		}
		self.repo = r;
		
		self.walker = [[[GTWalker alloc] initWithRepository:self error:error] autorelease];
		if(self.walker == nil) return nil;
	}
	return self;
}

- (id)initByCreatingRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error {
	
	if(self = [super init]){
		
		self.fileUrl = localFileUrl;
		
		GTLog("Creating repository in directory: %@", localFileUrl);
		
		git_repository *r;
		const char * path = [NSString utf8StringForString:[localFileUrl path]];
		int gitError = git_repository_init(&r, path, 0);
		if(gitError != GIT_SUCCESS) {
			if(error != NULL)
				*error = [NSError gitErrorForInitRepository:gitError];
			return nil;
		} 
		self.repo = r;
		
		self.walker = [[[GTWalker alloc] initWithRepository:self error:error] autorelease];
		if(self.walker == nil) return nil;
	}
	return self;
}

#pragma mark -
#pragma mark API 

+ (void)mapRawObject:(GTRawObject *)rawObj toObject:(git_rawobj *)obj {
	
	obj->type = rawObj.type;
	obj->len = 0;
	obj->data = NULL;
	if (rawObj.data != nil) {
		obj->len = [rawObj.data length];
		obj->data = malloc(obj->len);
		memcpy(obj->data, [rawObj.data bytes], obj->len);
	}
}

+ (NSString *)hash:(GTRawObject *)rawObj error:(NSError **)error {
	
	git_rawobj obj;
	git_oid oid;
	
	[GTRepository mapRawObject:rawObj toObject:&obj];
	
	int gitError = git_rawobj_hash(&oid, &obj);
	if(gitError != GIT_SUCCESS){
		if (error != NULL)
			*error = [NSError gitErrorForHashObject:gitError];
		return nil;
	}
	
	return [GTLib hexFromOid:&oid];
}

#pragma mark -
#pragma mark Properties

- (GTObject *)lookup:(NSString *)sha error:(NSError **)error {
	
	git_otype type = GIT_OBJ_ANY;
	git_oid oid;
	git_object *obj;
	
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:sha]);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
	
	gitError = git_object_lookup(&obj, self.repo, &oid, type);
	//int gitError = git_repository_lookup(&obj, self.repo, &oid, type);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForLookupSha:gitError];
		return nil;
	}
	
	return [GTObject objectInRepo:self withObject:obj];
}
- (BOOL)exists:(NSString *)sha error:(NSError **)error {
	return [self hasObject:sha error:error];
}
- (BOOL)hasObject:(NSString *)sha error:(NSError **)error{
	
	git_odb *odb;
	git_oid oid;
	
	odb = git_repository_database(self.repo);
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:sha]);
	if(gitError != GIT_SUCCESS){
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return NO;
	}
	
	return git_odb_exists(odb, &oid) ? YES : NO;
}

- (GTRawObject *)newRawObject:(const git_rawobj *)obj {
	
	return [GTRawObject rawObjectWithType:obj->type data:[NSData dataWithBytes:obj->data length:obj->len]];
}

- (GTRawObject *)rawRead:(const git_oid *)oid error:(NSError **)error {
	
	git_odb *odb;
	git_rawobj obj;
	
	odb = git_repository_database(self.repo);
	int gitError = git_odb_read(&obj, odb, oid);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForRawRead:gitError];
		return nil;
	}
	
	GTRawObject *rawObj = [self newRawObject:&obj];
	git_rawobj_close(&obj);
	
	return rawObj;
}

- (GTRawObject *)read:(NSString *)sha error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:sha]);
	if(gitError != GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
	return [self rawRead:&oid error:error];
}

- (NSString *)write:(GTRawObject *)rawObj error:(NSError **)error {
	
	git_odb *odb;
	git_rawobj obj;
	git_oid oid;
	
	odb = git_repository_database(self.repo);
	
	[GTRepository mapRawObject:rawObj toObject:&obj];
	int gitError = git_odb_write(&oid, odb, &obj);
	git_rawobj_close(&obj);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForWriteObjectToDb:gitError];
		return nil;
	}
	
	return [GTLib hexFromOid:&oid];
}

- (void)walk:(NSString *)sha sorting:(GTWalkerOptions)sortMode error:(NSError **)error block:(void (^)(GTCommit *commit))block {
	
	if(block == nil)return;

	[self.walker setSortingOptions:sortMode];
	[self.walker push:sha error:error];
	
	GTCommit *commit = nil;
	while((commit = [self.walker next]) != nil){
		block(commit);
	}
}

- (void)walk:(NSString *)sha error:(NSError **)error block:(void (^)(GTCommit *commit))block {
	
	[self walk:sha sorting:GIT_SORT_TIME  error:error block:block];
}

- (void)setupIndexAndReturnError:(NSError **)error {
	
	git_index *i;
	int gitError = git_repository_index(&i, self.repo);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForInitRepoIndex:gitError];
	}
	else {
		self.index = [GTIndex indexWithIndex:i];
	}
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	
	git_repository_free(self.repo);
	self.fileUrl = nil;
	self.walker.repo = nil;
	self.walker = nil;
	self.index = nil;
	[super dealloc];
}

@end
