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
#import "GTOdbObject.h"
#import "GTLib.h"
#import "GTIndex.h"
#import "GTBranch.h"
#import "GTTag.h"
#import "NSError+Git.h"
#import "NSString+Git.h"


@interface GTRepository ()
@property (nonatomic, assign) git_repository *repo;
@property (nonatomic, retain) NSURL *fileUrl;
@property (nonatomic, retain) GTWalker *walker;
@property (nonatomic, retain) GTIndex *index;
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
		
		//GTLog("Opening repository in directory: %@", localFileUrl);
		
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
		
		//GTLog("Creating repository in directory: %@", localFileUrl);
		
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


+ (NSString *)hash:(NSString *)data type:(GTObjectType)type error:(NSError **)error {
	
	git_oid oid;

	int gitError = git_odb_hash(&oid, [NSString utf8StringForString:data], [data length], type);
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

- (GTOdbObject *)rawRead:(const git_oid *)oid error:(NSError **)error {
	
	git_odb *odb;
	git_odb_object *obj;
	
	odb = git_repository_database(self.repo);
	int gitError = git_odb_read(&obj, odb, oid);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForRawRead:gitError];
		return nil;
	}
	
	GTOdbObject *rawObj = [GTOdbObject objectWithObject:obj];
	git_odb_object_close(obj);
	
	return rawObj;
}

- (GTOdbObject *)read:(NSString *)sha error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_oid_mkstr(&oid, [NSString utf8StringForString:sha]);
	if(gitError != GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
	return [self rawRead:&oid error:error];
}

// todo: get appropriate error messages here
- (NSString *)write:(NSString *)data type:(GTObjectType)type error:(NSError **)error {
	
	git_odb_stream *stream;
	git_odb *odb;
	git_oid oid;
	
	odb = git_repository_database(self.repo);
	
	int gitError = git_odb_open_wstream(&stream, odb, data.length, type);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to open write stream on odb"];
		return nil;
	}
	
	gitError = stream->write(stream, [NSString utf8StringForString:data], data.length);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to write to stream on odb"];
		return nil;
	}
	
	gitError = stream->finalize_write(&oid, stream);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to finalize write on odb"];
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
	
	[self.walker setSortingOptions:sortMode];
	BOOL success = [self.walker push:sha error:error];
	if(!success) return NO; 
	
	GTCommit *commit = nil;
	while((commit = [self.walker next]) != nil) {
		BOOL stop = NO;
		block(commit, &stop);
		if(stop) break;
	}
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
