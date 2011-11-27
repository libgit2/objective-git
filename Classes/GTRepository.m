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
#import "GTObjectDatabase.h"
#import "GTIndex.h"
#import "GTBranch.h"
#import "GTTag.h"
#import "NSError+Git.h"
#import "NSString+Git.h"


@interface GTRepository ()
@property (nonatomic, assign) git_repository *repo;
@property (nonatomic, retain) NSURL *fileUrl;
@property (nonatomic, retain) GTEnumerator *enumerator;
@property (nonatomic, retain) GTIndex *index;
@property (nonatomic, retain) GTObjectDatabase *objectDatabase;
@end

@implementation GTRepository

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> fileURL: %@", NSStringFromClass([self class]), self, self.fileUrl];
}

- (void)dealloc {
	
	if(self.repo != NULL) git_repository_free(self.repo);
	self.fileUrl = nil;
	self.enumerator.repository = nil;
	self.enumerator = nil;
	self.index = nil;
    self.objectDatabase = nil;
	[super dealloc];
}

- (void)finalize {
	
	if(self.repo != NULL) git_repository_free(self.repo);
	[super finalize];
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
    
    if ([[url path] hasSuffix:@".git"] == NO && [GTRepository isAGitDirectory:url] == NO) 
	{
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
@synthesize objectDatabase;

+ (BOOL)initializeEmptyRepositoryAtURL:(NSURL *)localFileURL error:(NSError **)error {

    const char *path = [[localFileURL path] UTF8String];
    
    git_repository *r;
    int gitError = git_repository_init(&r, path, 0);
    if (gitError < GIT_SUCCESS) {
        if (error != NULL) {
            *error = [NSError git_errorFor:gitError withDescription:@"Failed to initialize repository."];
        }
    }
    
    return (gitError == GIT_SUCCESS);
}

+ (GTRepository*)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error {

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
        
        if (gitError < GIT_SUCCESS) {
            if (error != NULL) {
                *error = [NSError git_errorFor:gitError withDescription:@"Failed to open repository."];
            }
            [self release];
            return nil;
        }
        self.repo = r;
		
		self.enumerator = [[[GTEnumerator alloc] initWithRepository:self error:error] autorelease];
		if (self.enumerator == nil) {
            [self release];
            return nil;
        }

		self.fileUrl = localFileURL;
        self.objectDatabase = [GTObjectDatabase objectDatabaseWithRepository:self];
    }
    return self;
}

+ (NSString *)hash:(NSString *)data objectType:(GTObjectType)type error:(NSError **)error {
	
	git_oid oid;

	int gitError = git_odb_hash(&oid, [data UTF8String], [data length], (git_otype) type);
	if(gitError < GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError git_errorFor:gitError withDescription:@"Failed to get hash for object."];
		return nil;
	}
	
	return [NSString git_stringWithOid:&oid];
}

- (GTObject *)lookupObjectByOid:(git_oid *)oid objectType:(GTObjectType)type error:(NSError **)error {
	
	git_object *obj;
	
	int gitError = git_object_lookup(&obj, self.repo, oid, (git_otype) type);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withDescription:@"Failed to lookup object in repository."];
		return nil;
	}
	
    return [GTObject objectWithObj:obj inRepository:self];
}

- (GTObject *)lookupObjectByOid:(git_oid *)oid error:(NSError **)error {
	
	return [self lookupObjectByOid:oid objectType:GTObjectTypeAny error:error];
}

- (GTObject *)lookupObjectBySha:(NSString *)sha objectType:(GTObjectType)type error:(NSError **)error {
	
	git_oid oid;
	
	int gitError = git_oid_fromstr(&oid, [sha UTF8String]);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorForMkStr:gitError];
		return nil;
	}
	
	return [self lookupObjectByOid:&oid objectType:type error:error];
}

- (GTObject *)lookupObjectBySha:(NSString *)sha error:(NSError **)error {
	
	return [self lookupObjectBySha:sha objectType:GTObjectTypeAny error:error];
}

- (BOOL)enumerateCommitsBeginningAtSha:(NSString *)sha sortOptions:(GTEnumeratorOptions)options error:(NSError **)error usingBlock:(void (^)(GTCommit *, BOOL *))block {
    
	if(block == nil) {
		if(error != NULL)
			*error = [NSError git_errorWithDescription:@"No block was provided to the method."];
		return NO;
	}
    
	if(sha == nil) {
		GTReference *head = [self headReferenceWithError:error];
		if(head == nil) return NO;
		sha = head.target;
	}
	
	[self.enumerator reset];
	[self.enumerator setOptions:options];
	BOOL success = [self.enumerator push:sha error:error];
	if(!success) return NO; 
	
	GTCommit *commit = nil;
	while((commit = [self.enumerator nextObjectWithError:error]) != nil) {
		BOOL stop = NO;
		block(commit, &stop);
		if(stop) break;
	}
	
	if(error == NULL) {
		return YES;
	}
	
	return *error == nil;
}

- (BOOL)enumerateCommitsBeginningAtSha:(NSString *)sha error:(NSError **)error usingBlock:(void (^)(GTCommit *, BOOL *))block; {
    
	return [self enumerateCommitsBeginningAtSha:sha sortOptions:GTEnumeratorOptionsTimeSort error:error usingBlock:block];
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

- (BOOL)setupIndexWithError:(NSError **)error {
	
	git_index *i;
	int gitError = git_repository_index(&i, self.repo);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withDescription:@"Failed to get index for repository."];
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

- (NSArray *)allReferenceNamesWithError:(NSError **)error {
	
	return [GTReference referenceNamesInRepository:self error:error];
}

- (NSArray *)allBranchesWithError:(NSError **)error {
    
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
		
		NSMutableArray *branches = [NSMutableArray array];
		if(localBranch.remoteBranches != nil) {
			[branches addObjectsFromArray:localBranch.remoteBranches];
		}
		[branches addObject:branch];
		localBranch.remoteBranches = branches;
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
	NSMutableArray *matchedRemoteBranches = [NSMutableArray array];
	for(GTBranch *branch in remoteBranches) {
		if([branch.shortName isEqualToString:currentBranch.shortName]) {
			[matchedRemoteBranches addObject:branch];
		}
	}
	
	currentBranch.remoteBranches = matchedRemoteBranches;
	
	return currentBranch;
}

- (NSArray *)localCommitsRelativeToRemoteBranch:(GTBranch *)remoteBranch error:(NSError **)error {
	
	if(remoteBranch == nil) {
		return [NSArray array];
	}
	
	GTBranch *localBranch = [self currentBranchWithError:error];
	if(localBranch == nil) {
		return nil;
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
	GTCommit *currentCommit = [localBranchEnumerator nextObjectWithError:error];
	while(currentCommit != nil) {
		if([currentCommit.sha isEqualToString:remoteBranchTip]) {
			break;
		}
		
		[commits addObject:currentCommit];
		
		currentCommit = [localBranchEnumerator nextObjectWithError:error];
	}
	
	return commits;
}

- (GTRepository *)repository {
    
	return self;
}

@end
