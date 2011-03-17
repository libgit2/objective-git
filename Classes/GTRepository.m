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
#import "GTBranch.h"
#import "GTTag.h"
#import "NSError+Git.h"
#import "NSString+Git.h"


@interface GTRepository ()
@property (nonatomic, retain) GTWalker *walker;
@end

@implementation GTRepository

- (void)dealloc {
	
	git_repository_free(self.repo);
	self.fileUrl = nil;
	self.walker.repo = nil;
	self.walker = nil;
	self.index = nil;
	[super dealloc];
}

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

+ (BOOL)isAGitDirectory:(NSURL *)directory {
	
	NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
	BOOL isDir = NO;
	NSURL *headFileURL = [directory URLByAppendingPathComponent:@"HEAD"];
	
	if([fm fileExistsAtPath:[headFileURL path] isDirectory:&isDir] && !isDir) {
		NSURL *objectsDir = [directory URLByAppendingPathComponent:@"objects"];
		if([fm fileExistsAtPath:[objectsDir path] isDirectory:&isDir] && isDir) {
			return YES;
		}
	}
	return NO;
}

#pragma mark -
#pragma mark API 

@synthesize repo;
@synthesize fileUrl;
@synthesize walker;
@synthesize index;

- (id)initByOpeningRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error {
	
	if((self = [super init])) {
		
		self.fileUrl = localFileUrl;
		
		GTLog("Opening repository in directory: %@", localFileUrl);
		
		const char *path;
		if([[localFileUrl path] hasSuffix:@".git"] && [GTRepository isAGitDirectory:localFileUrl]) {
            path = [NSString utf8StringForString:[localFileUrl path]];
		}
		else {
			path = [NSString utf8StringForString:[[localFileUrl URLByAppendingPathComponent:@".git"] path]];
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
+ (id)repoByOpeningRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error {
	
	return [[[self alloc]initByOpeningRepositoryInDirectory:localFileUrl error:error] autorelease];
}

- (id)initByCreatingRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error {
	
	if((self = [super init])) {
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
+ (id)repoByCreatingRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error {
	
	return [[[self alloc]initByCreatingRepositoryInDirectory:localFileUrl error:error] autorelease];
}

+ (NSString *)hash:(GTRawObject *)rawObj error:(NSError **)error {
	
	git_rawobj obj;
	git_oid oid;
	
	[GTRepository mapRawObject:rawObj toObject:&obj];
	
	int gitError = git_rawobj_hash(&oid, &obj);
	if(gitError != GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError gitErrorForHashObject:gitError];
		return nil;
	}
	
	return [GTLib convertOidToSha:&oid];
}

- (GTObject *)lookupByOid:(git_oid *)oid type:(GTObjectType)type error:(NSError **)error {
	
	git_object *obj;
	
	int gitError = git_object_lookup(&obj, self.repo, oid, type);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForLookupObject:gitError];
		return nil;
	}
	
	return [GTObject objectInRepo:self withObject:obj];
}

- (GTObject *)lookupByOid:(git_oid *)oid error:(NSError **)error {
	
	return [self lookupByOid:oid type:GTObjectTypeAny error:error];
}

- (GTObject *)lookupBySha:(NSString *)sha type:(GTObjectType)type error:(NSError **)error {
	
	git_oid oid;
	
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:sha]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
	
	return [self lookupByOid:&oid type:type error:error];
}

- (GTObject *)lookupBySha:(NSString *)sha error:(NSError **)error {
	
	return [self lookupBySha:sha type:GTObjectTypeAny error:error];
}

- (BOOL)exists:(NSString *)sha error:(NSError **)error {
	
	return [self hasObject:sha error:error];
}

- (BOOL)hasObject:(NSString *)sha error:(NSError **)error{
	
	git_odb *odb;
	git_oid oid;
	
	odb = git_repository_database(self.repo);
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:sha]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return NO;
	}
	
	return git_odb_exists(odb, &oid) ? YES : NO;
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
	
	GTRawObject *rawObj = [GTRawObject rawObjectWithRawObject:&obj];
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
	
	return [GTLib convertOidToSha:&oid];
}

- (BOOL)walk:(NSString *)sha sorting:(GTWalkerOptions)sortMode error:(NSError **)error block:(void (^)(GTCommit *commit, BOOL *stop))block {
	
	if(block == nil) {
		if(error != NULL)
			*error = [NSError gitErrorForNoBlockProvided];
		return NO;	
	}

	if(sha == nil) {
		GTReference *head = [self headAndReturnError:error];
		if(head == nil) return NO;
		sha = head.target;
	}
	
	//[self.walker reset];
	[self.walker setSortingOptions:sortMode];
	BOOL success = [self.walker push:sha error:error];
	if(!success) return NO; 
	
	GTCommit *commit = nil;
	while((commit = [self.walker next]) != nil) {
		BOOL stop = NO;
		block(commit, &stop);
		if(stop) break;
	}
	//[self.walker reset];
	return YES;
}

- (BOOL)walk:(NSString *)sha error:(NSError **)error block:(void (^)(GTCommit *commit, BOOL *stop))block {
	
	return [self walk:sha sorting:GIT_SORT_TIME error:error block:block];
}

- (BOOL)setupIndexAndReturnError:(NSError **)error {
	
	git_index *i;
	int gitError = git_repository_index(&i, self.repo);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForInitRepoIndex:gitError];
		return NO;
	}
	else {
		self.index = [GTIndex indexWithIndex:i];
		return YES;
	}
}

- (GTReference *)headAndReturnError:(NSError **)error {
	
	GTReference *headSymRef = [GTReference referenceByLookingUpRef:@"HEAD" inRepo:self error:error];
	if(headSymRef == nil) return nil;
	
	return [GTReference referenceByResolvingRef:headSymRef error:error];
}

- (NSArray *)listReferenceNamesOfTypes:(GTReferenceTypes)types error:(NSError **)error {
	
	return [GTReference listReferenceNamesInRepo:self types:types error:error];
}

- (NSArray *)listAllReferenceNamesAndReturnError:(NSError **)error {
	
	return [GTReference listAllReferenceNamesInRepo:self error:error];
}

- (NSArray *)listAllBranchesAndReturnError:(NSError **)error {
    
    return [GTBranch listAllBranchesInRepository:self error:error];
}

- (NSInteger)numberOfCommitsInCurrentBranchAndReturnError:(NSError **)error {
	
	GTReference *head = [self headAndReturnError:error];
	if(head == nil) return NSNotFound;
	
	return [self.walker countFromSha:head.target error:error];
}

@end
