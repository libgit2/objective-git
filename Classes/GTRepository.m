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
#import "GTConfiguration.h"

@interface GTRepository ()
@property (nonatomic, assign) git_repository *git_repository;
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) GTEnumerator *enumerator;
@property (nonatomic, strong) GTIndex *index;
@property (nonatomic, strong) GTObjectDatabase *objectDatabase;
@property (nonatomic, strong) NSMutableSet *weakEnumerators;
@property (nonatomic, strong) GTConfiguration *configuration;
@end


@implementation GTRepository

@synthesize enumerator;

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> fileURL: %@", NSStringFromClass([self class]), self, self.fileURL];
}

- (void)dealloc {
	// Alright so git_revwalk needs to be free'd before the repository it points to is free'd, otherwise the odb is double-free'd and it crashes. But GTEnumerator shouldn't have to know anything about the lifetime of its GTRepository to keep from crashing. So the repository keeps track of all the enumerators pointing to it and nils out their repository when they're being dealloc'd. That tells the enumerator that it should go ahead and free its revwalk. And so life goes on.
	for(NSValue *weakWrappedValue in self.weakEnumerators) {
		[[weakWrappedValue nonretainedObjectValue] setRepository:nil];
	}
	
	if(self.git_repository != NULL) git_repository_free(self.git_repository);
}


#pragma mark API

+ (BOOL)isAGitDirectory:(NSURL *)directory {
	NSFileManager *fm = [[NSFileManager alloc] init];
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

+ (id)repositoryWithURL:(NSURL *)localFileURL error:(NSError **)error {
    return [[self alloc] initWithURL:localFileURL error:error];
}

@synthesize git_repository;
@synthesize fileURL;
@synthesize index;
@synthesize objectDatabase;
@synthesize weakEnumerators;
@synthesize configuration;

- (id)initWithURL:(NSURL *)localFileURL error:(NSError **)error {
    localFileURL = [[self class] _gitURLForURL:localFileURL error:error];
    if (localFileURL == nil) {
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
            return nil;
        }
        self.git_repository = r;

		self.fileURL = localFileURL;
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
	
	int gitError = git_object_lookup(&obj, self.git_repository, oid, (git_otype) type);
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
	NSParameterAssert(block != NULL);
    
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
	int gitError = git_repository_index(&i, self.git_repository);
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

- (NSArray *)localBranchesWithError:(NSError **)error {
    return [self branchesWithPrefix:[GTBranch localNamePrefix] error:error];
}

- (NSArray *)remoteBranchesWithError:(NSError **)error {
	static NSArray *unwantedRemoteBranches = nil;
	if(unwantedRemoteBranches == nil) {
		unwantedRemoteBranches = [NSArray arrayWithObjects:@"HEAD", nil];
	}
	
	NSArray *remoteBranches = [self branchesWithPrefix:[GTBranch remoteNamePrefix] error:error];
	if(remoteBranches == nil) return nil;
	
	NSMutableArray *filteredList = [NSMutableArray arrayWithCapacity:remoteBranches.count];
	for(GTBranch *branch in remoteBranches) {
		if(![unwantedRemoteBranches containsObject:branch.shortName]) {
			[filteredList addObject:branch];
		}
	}
	
	return filteredList;
}

- (NSArray *)branchesWithPrefix:(NSString *)prefix error:(NSError **)error {
	NSArray *references = [self referenceNamesWithError:error];
    if(references == nil) return nil;
	
    NSMutableArray *branches = [NSMutableArray array];
    for(NSString *ref in references) {
        if([ref hasPrefix:prefix]) {
            GTBranch *b = [GTBranch branchWithName:ref repository:self error:error];
            if(b != nil)
                [branches addObject:b];
        }
    }
    return branches;
}

- (NSArray *)allBranchesWithError:(NSError **)error {
	NSMutableArray *allBranches = [NSMutableArray array];
	NSArray *localBranches = [self localBranchesWithError:error];
	NSArray *remoteBranches = [self remoteBranchesWithError:error];
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

- (NSUInteger)numberOfCommitsInCurrentBranch:(NSError **)error {
	GTReference *head = [self headReferenceWithError:error];
	if(head == nil) return NSNotFound;
	
	return [self.enumerator countFromSha:head.target error:error];
}

- (GTBranch *)createBranchNamed:(NSString *)name fromReference:(GTReference *)ref error:(NSError **)error {
	GTReference *newRef = [GTReference referenceByCreatingReferenceNamed:[NSString stringWithFormat:@"%@%@", [GTBranch localNamePrefix], name] fromReferenceTarget:[ref target] inRepository:self error:error];
	return [GTBranch branchWithReference:newRef repository:self];
}

- (BOOL)isEmpty {
	return (BOOL) git_repository_is_empty(self.git_repository);
}

- (GTBranch *)currentBranchWithError:(NSError **)error {
	GTReference *head = [self headReferenceWithError:error];
	if (head == nil) return nil;
	
	GTBranch *currentBranch = [GTBranch branchWithReference:head repository:self];
	
	NSArray *remoteBranches = [self remoteBranchesWithError:error];
	if(remoteBranches == nil) return nil;
	
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

- (NSArray *)referenceNamesWithTypes:(GTReferenceTypes)types error:(NSError **)error {
	git_strarray array;
	
	int gitError = git_reference_listall(&array, self.git_repository, types);
	if(gitError < GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withDescription:@"Failed to list all references."];
		return nil;
	}
	
	NSMutableArray *references = [NSMutableArray arrayWithCapacity:array.count];
	for(NSUInteger i = 0; i < array.count; i++) {
		[references addObject:[NSString stringWithUTF8String:array.strings[i]]];
	}
	
	git_strarray_free(&array);
	
	return references;
}

- (NSArray *)referenceNamesWithError:(NSError **)error {
	return [self referenceNamesWithTypes:GTReferenceTypesListAll error:error];
}

- (GTRepository *)repository {
	return self;
}

- (GTObjectDatabase *)objectDatabase {
	if(objectDatabase == nil) {
		self.objectDatabase = [GTObjectDatabase objectDatabaseWithRepository:self];
	}
	
	return objectDatabase;
}

- (GTEnumerator *)enumerator {
	if(enumerator == nil) {
		self.enumerator = [[GTEnumerator alloc] initWithRepository:self error:NULL];
	}
	
	return enumerator;
}

- (BOOL)isBare {
	return self.git_repository && git_repository_is_bare(self.git_repository);
}

- (BOOL)isHeadDetached {
	return (BOOL) git_repository_head_detached(self.git_repository);
}

- (NSMutableSet *)weakEnumerators {
	if(weakEnumerators == nil) {
		self.weakEnumerators = [NSMutableSet set];
	}
	
	return weakEnumerators;
}

- (GTConfiguration *)configuration {
	if(configuration == nil) {
		git_config *config = NULL;
		int error = git_repository_config(&config, self.git_repository);
		if(error < GIT_SUCCESS) {
			
		}
		
		self.configuration = [GTConfiguration configurationWithConfiguration:config];
	}
	
	return configuration;
}

- (GTIndex *)index {
	if(index == nil) {
		NSError *error = nil;
		BOOL success = [self setupIndexWithError:&error];
		if(!success) {
			GTLog(@"Error setting up index: %@", error);
		}
	}
	
	return index;
}

@end


@implementation GTRepository (Private)

- (void)addEnumerator:(GTEnumerator *)e {
	[self.weakEnumerators addObject:[NSValue valueWithNonretainedObject:e]];
}

- (void)removeEnumerator:(GTEnumerator *)e {
	[self.weakEnumerators removeObject:[NSValue valueWithNonretainedObject:e]];
}

@end
