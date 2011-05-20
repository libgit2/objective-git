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
#import "GTEnumerator.h"
#import "GTObject.h"
#import "GTCommit.h"
#import "GTOdbObject.h"
#import "GTLib.h"
#import "GTIndex.h"
#import "GTBranch.h"
#import "GTTag.h"
#import "NSError+Git.h"


@interface GTRepository ()
@property (nonatomic, assign) git_repository *repo;
@property (nonatomic, retain) NSURL *fileUrl;
@property (nonatomic, retain) GTEnumerator *enumerator;
@property (nonatomic, retain) GTIndex *index;
@end

@interface GTEnumerator ()
@property (nonatomic, assign) BOOL checksForMainThreadViolations;
@end

@implementation GTRepository

- (void)dealloc {
	
	git_repository_free(self.repo);
	self.fileUrl = nil;
	self.enumerator = nil;
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

+ (NSURL *)_gitURLForURL:(NSURL *)url error:(NSError **)error {

    if ([url isFileURL] == NO) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:kCFURLErrorUnsupportedURL userInfo:[NSDictionary dictionaryWithObject:@"not a local file URL" forKey:NSLocalizedDescriptionKey]];
        }
        return nil;
    }
    
    if ([[url path] hasSuffix:@".git"] == NO || [GTRepository isAGitDirectory:url] == NO) {
        url = [url URLByAppendingPathComponent:@".git"];
    }
    return url;
}

#pragma mark -
#pragma mark API 

@synthesize repo;
@synthesize fileUrl;
@synthesize enumerator;
@synthesize index;

+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL error:(NSError **)error {

    const char *path = [[localFileURL path] UTF8String];
    
    git_repository *r;
    int gitError = git_repository_init(&r, path, 0);
    if (gitError != GIT_SUCCESS) {
        if (error != NULL) {
            *error = [NSError gitErrorForInitRepository:gitError];
        }
    }
    
    return (gitError == GIT_SUCCESS);
}

+ (id)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error {

    return [[[self alloc] initWithURL:localFileURL error:error] autorelease];
}

- (id)initWithURL:(NSURL *)localFileURL error:(NSError **)error {

    localFileURL = [[self class] _gitURLForURL:localFileURL error:error];
    if (localFileURL == nil) {
        [self release];
        return nil;
    }
    
    self = [super init];
    if (self) {
        git_repository *r;
        int gitError = git_repository_open(&r, [[localFileURL path] UTF8String]);
        
        if (gitError != GIT_SUCCESS) {
            if (error != NULL) {
                *error = [NSError gitErrorForOpenRepository:gitError];
            }
            [self release];
            return nil;
        }
        self.repo = r;
		
		self.enumerator = [GTEnumerator enumeratorWithRepository:self error:error];
		if (self.enumerator == nil) {
            [self release];
            return nil;
        }
        self.enumerator.checksForMainThreadViolations = YES;

		self.fileUrl = localFileURL;
    }
    return self;
}

+ (NSString *)hash:(NSString *)data type:(GTObjectType)type error:(NSError **)error {
	
	git_oid oid;

	int gitError = git_odb_hash(&oid, [data UTF8String], [data length], type);
	if(gitError != GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError gitErrorForHashObject:gitError];
		return nil;
	}
	
	return [GTLib convertOidToSha:&oid];
}


- (GTObject *)lookupObjectByOid:(git_oid *)oid type:(GTObjectType)type error:(NSError **)error {
	
	git_object *obj;
	
	int gitError = git_object_lookup(&obj, self.repo, oid, type);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForLookupObject:gitError];
		return nil;
	}
	
    return [GTObject objectWithObj:obj inRepository:self];
}

- (GTObject *)lookupObjectByOid:(git_oid *)oid error:(NSError **)error {
	
	return [self lookupObjectByOid:oid type:GTObjectTypeAny error:error];
}

- (GTObject *)lookupObjectBySha:(NSString *)sha type:(GTObjectType)type error:(NSError **)error {
	
	git_oid oid;
	
	int gitError = git_oid_mkstr(&oid, [sha UTF8String]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
	
	return [self lookupObjectByOid:&oid type:type error:error];
}

- (GTObject *)lookupObjectBySha:(NSString *)sha error:(NSError **)error {
	
	return [self lookupObjectBySha:sha type:GTObjectTypeAny error:error];
}

- (BOOL)exists:(NSString *)sha error:(NSError **)error {
	
	return [self hasObject:sha error:error];
}

- (BOOL)hasObject:(NSString *)sha error:(NSError **)error{
	
	git_odb *odb;
	git_oid oid;
	
	odb = git_repository_database(self.repo);
	int gitError = git_oid_mkstr(&oid, [sha UTF8String]);
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
	
	GTOdbObject *rawObj = [GTOdbObject objectWithOdbObj:obj];
	git_odb_object_close(obj);
	
	return rawObj;
}

- (GTOdbObject *)read:(NSString *)sha error:(NSError **)error {
	
	git_oid oid;
	int gitError = git_oid_mkstr(&oid, [sha UTF8String]);
	if(gitError != GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
	return [self rawRead:&oid error:error];
}

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
	
	gitError = stream->write(stream, [data UTF8String], data.length);
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

- (void)enumerateCommitsBeginningAtSha:(NSString *)sha sortOptions:(GTEnumeratorOptions)options error:(NSError **)error usingBlock:(void (^)(GTCommit *, BOOL*))block {
    
	if(block == nil) {
		if(error != NULL)
			*error = [NSError gitErrorForNoBlockProvided];
		return;
	}
    
	if(sha == nil) {
		GTReference *head = [self headReferenceWithError:error];
		if(head == nil) return;
		sha = head.target;
	}
	
	[self.enumerator reset];
	[self.enumerator setOptions:options];
	BOOL success = [self.enumerator push:sha error:error];
	if(!success) return; 
	
	GTCommit *commit = nil;
	while((commit = [self.enumerator nextObject]) != nil) {
		BOOL stop = NO;
		block(commit, &stop);
		if(stop) break;
	}
}

- (void)enumerateCommitsBeginningAtSha:(NSString *)sha error:(NSError **)error usingBlock:(void (^)(GTCommit *, BOOL*))block {
    [self enumerateCommitsBeginningAtSha:sha sortOptions:GTEnumeratorOptionsTimeSort error:error usingBlock:block];
}

- (NSArray *)selectCommitsBeginningAtSha:(NSString *)sha error:(NSError **)error block:(BOOL (^)(GTCommit *commit, BOOL *stop))block {
	
	NSMutableArray *passingCommits = [NSMutableArray array];
    [self enumerateCommitsBeginningAtSha:sha error:error usingBlock:^(GTCommit *commit, BOOL *stop) {
		BOOL passes = block(commit, stop);
		if(passes) {
			[passingCommits addObject:commit];
		}
    }];
    return passingCommits;
}

- (BOOL)setupIndex:(NSError **)error {
	
	git_index *i;
	int gitError = git_repository_index(&i, self.repo);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForInitRepoIndex:gitError];
		return NO;
	}
	else {
		self.index = [GTIndex indexWithGitIndex:i];
		return YES;
	}
}

- (GTReference *)headReferenceWithError:(NSError **)error {
	
	GTReference *headSymRef = [GTReference referenceByLookingUpReferencedNamed:@"HEAD" inRepository:self error:error];
	if(headSymRef == nil) return nil;
	
	return [GTReference referenceByResolvingSymbolicReference:headSymRef error:error];
}

- (NSArray *)allReferenceNamesOfTypes:(GTReferenceTypes)types error:(NSError **)error {
	
	return [GTReference referenceNamesInRepository:self types:types error:error];
}

- (NSArray *)allReferenceNames:(NSError **)error {
	
	return [GTReference referenceNamesInRepository:self error:error];
}

- (NSArray *)allBranches:(NSError **)error {
    
	NSMutableArray *allBranches = [NSMutableArray array];
	NSArray *localBranches = [GTBranch branchesInRepository:self error:error];
	NSArray *remoteBranches = [GTBranch remoteBranchesInRepository:self error:error];
	if(localBranches == nil || remoteBranches == nil) return nil;
	
	[allBranches addObjectsFromArray:localBranches];
	
	// we want to add the remote branches that we don't already have as a local branch
	NSMutableDictionary *shortNamesToBranches = [NSMutableDictionary dictionary];
	for(GTBranch *branch in localBranches) {
		[shortNamesToBranches setObject:branch forKey:branch.shortName];
	}
	
	for(GTBranch *branch in remoteBranches) {
		GTBranch *localBranch = [shortNamesToBranches objectForKey:branch.shortName];
		if(localBranch == nil) {
			[allBranches addObject:branch];
		}
		
		localBranch.remoteBranch = branch;
	}
	
    return allBranches;
}

- (NSInteger)numberOfCommitsInCurrentBranch:(NSError **)error {
	
	GTReference *head = [self headReferenceWithError:error];
	if(head == nil) return NSNotFound;
	
	return [self.enumerator countFromSha:head.target error:error];
}

- (GTBranch *)createBranchNamed:(NSString *)name fromReference:(GTReference *)ref error:(NSError **)error {
	
	GTReference *newRef = [GTReference referenceByCreatingReferenceNamed:[NSString stringWithFormat:@"%@%@", [GTBranch localNamePrefix], name] fromReferenceTarget:[ref target] inRepository:self error:error];
	return [GTBranch branchWithReference:newRef repository:self];
}

- (BOOL)isEmpty {
	return git_repository_is_empty(self.repo);
}

- (GTBranch *)currentBranchWithError:(NSError **)error {
	
	GTReference *head = [self headReferenceWithError:error];
	if (head == nil) return nil;
	
	GTBranch *currentBranch = [GTBranch branchWithReference:head repository:self];
	
	NSArray *remoteBranches = [GTBranch remoteBranchesInRepository:self error:error];
	for(GTBranch *branch in remoteBranches) {
		if([branch.shortName isEqualToString:currentBranch.shortName]) {
			currentBranch.remoteBranch = branch;
			break;
		}
	}
	
	return currentBranch;
}

- (NSArray *)localCommitsWithError:(NSError **)error {
	
	GTBranch *localBranch = [self currentBranchWithError:error];
	if(localBranch == nil) {
		return nil;
	}
	
	GTBranch *remoteBranch = localBranch.remoteBranch;
	if(remoteBranch == nil) {
		return [NSArray array];
	}
	
	GTEnumerator *localBranchEnumerator = [GTEnumerator enumeratorWithRepository:self error:error];
	if(localBranchEnumerator == nil) {
		return nil;
	}
	
	[localBranchEnumerator setOptions:GTEnumeratorOptionsTopologicalSort];
	
	BOOL success = [localBranchEnumerator push:localBranch.sha error:error];
	if(!success) {
		return nil;
	}
	
	NSString *remoteBranchTip = remoteBranch.sha;
	NSMutableArray *commits = [NSMutableArray array];
	GTCommit *currentCommit = [localBranchEnumerator nextObject];
	while(currentCommit != nil) {
		if([currentCommit.sha isEqualToString:remoteBranchTip]) {
			break;
		}
		
		[commits addObject:currentCommit];
		
		currentCommit = [localBranchEnumerator nextObject];
	}
	
	return commits;
}

- (GTRepository *)repository {
    return self;
}

@end
