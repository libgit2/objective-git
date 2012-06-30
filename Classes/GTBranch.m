//
//  GTBranch.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 3/3/11.
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

#import "GTBranch.h"
#import "GTReference.h"
#import "GTEnumerator.h"
#import "GTRepository.h"
#import "GTCommit.h"
#import "NSError+Git.h"


@interface GTBranch ()
@property (nonatomic, strong) GTReference *reference;
@property (nonatomic, unsafe_unretained) GTRepository *repository;
@end

@implementation GTBranch

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> name: %@, shortName: %@, sha: %@, remoteName: %@, repository: %@", NSStringFromClass([self class]), self, self.name, self.shortName, self.sha, self.remoteName, self.repository];
}

- (BOOL)isEqual:(id)otherObject {
	if(![otherObject isKindOfClass:[GTBranch class]]) {
		return NO;
	}
	
	GTBranch *otherBranch = otherObject;
	
	return [self.name isEqualToString:otherBranch.name];
}

- (NSUInteger)hash {
	return [self.name hash];
}


#pragma mark API

@synthesize reference;
@synthesize repository;
@synthesize remoteBranches;

+ (NSString *)localNamePrefix {
	return @"refs/heads/";
}

+ (NSString *)remoteNamePrefix {
	return @"refs/remotes/";
}

+ (id)branchWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error {	
	return [[self alloc] initWithName:branchName repository:repo error:error];
}

+ (id)branchWithReference:(GTReference *)ref repository:(GTRepository *)repo {
	return [[self alloc] initWithReference:ref repository:repo];
}

- (id)initWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error {
	if((self = [super init])) {
		self.reference = [GTReference referenceByLookingUpReferencedNamed:branchName inRepository:repo error:error];
		if(self.reference == nil) {
            return nil;
        }
		
		self.repository = repo;
	}
	return self;
}

- (id)initWithReference:(GTReference *)ref repository:(GTRepository *)repo {
	if((self = [super init])) {
		self.reference = ref;
		self.repository = repo;
	}
	return self;
}

- (NSString *)name {
	return self.reference.name;
}

- (NSString *)shortName {
	if([self branchType] == GTBranchTypeLocal) {
		return [self.name stringByReplacingOccurrencesOfString:[[self class] localNamePrefix] withString:@""];
	} else if([self branchType] == GTBranchTypeRemote) {
		// remote repos also have their remote in their name
		NSString *remotePath = [[[self class] remoteNamePrefix] stringByAppendingFormat:@"%@/", [self remoteName]];
		return [self.name stringByReplacingOccurrencesOfString:remotePath withString:@""];
	} else {
		return self.name;
	}
}

- (NSString *)sha {
	return self.reference.target;
}

- (NSString *)remoteName {
	if([self branchType] == GTBranchTypeLocal) {
		return nil;
	}
	
	NSArray *components = [self.name componentsSeparatedByString:@"/"];
	// refs/heads/origin/branch_name
	if(components.count < 4) {
		return nil;
	}
	
	return [components objectAtIndex:2];
}

- (GTCommit *)targetCommitAndReturnError:(NSError **)error {
    return (GTCommit *)[self.repository lookupObjectBySha:self.sha error:error];
}

- (NSUInteger)numberOfCommitsWithError:(NSError **)error {
	return [self.repository.enumerator countFromSha:self.sha error:error];
}

- (GTBranchType)branchType {
    if ([self.name hasPrefix:[[self class] remoteNamePrefix]]) {
        return GTBranchTypeRemote;
    }
    return GTBranchTypeLocal;
}

- (GTBranch *)remoteBranchForRemoteName:(NSString *)remote {
	for(GTBranch *remoteBranch in self.remoteBranches) {
		if([remoteBranch.remoteName isEqualToString:remote]) {
			return remoteBranch;
		}
	}
	
	return nil;
}

- (NSArray *)remoteBranches {
	if(remoteBranches != nil) {
		return remoteBranches;
	} else if(self.branchType == GTBranchTypeRemote) {
		return [NSArray arrayWithObject:self];
	}
	
	return nil;
}

+ (GTCommit *)mergeBaseOf:(GTBranch *)branch1 andBranch:(GTBranch *)branch2 error:(NSError **)error {
	NSAssert2([branch1.repository isEqual:branch2.repository], @"Both branches must be in the same repository: %@ vs. %@", branch1.repository, branch2.repository);
	
	git_oid mergeBase;
	int errorCode = git_merge_base(&mergeBase, branch1.repository.git_repository, (git_oid *) branch1.reference.oid, (git_oid *) branch2.reference.oid);
	if(errorCode < GIT_OK) {
		if(error != NULL) {
			*error = [NSError git_errorFor:errorCode withAdditionalDescription:NSLocalizedString(@"", @"")];
		}
		
		return nil;
	}
	
	return (GTCommit *) [branch1.repository lookupObjectByOid:&mergeBase objectType:GTObjectTypeCommit error:error];
}

- (NSArray *)uniqueCommitsRelativeToBranch:(GTBranch *)otherBranch error:(NSError **)error {
	if(otherBranch == nil) return [NSArray array];
	
	GTCommit *mergeBase = [[self class] mergeBaseOf:self andBranch:otherBranch error:error];
	if(mergeBase == nil) return nil;
	
	GTEnumerator *enumerator = self.repository.enumerator;
	if(enumerator == nil) return nil;
	
	NSArray * (^allCommitsFromSha)(NSString *, NSError **) = ^NSArray *(NSString *sha, NSError **localError) {
		[enumerator reset];
		[enumerator setOptions:GTEnumeratorOptionsTopologicalSort];
		
		BOOL success = [enumerator push:sha error:localError];
		if(!success) return nil;
		
		NSMutableArray *commits = [NSMutableArray array];
		GTCommit *currentCommit = [enumerator nextObjectWithError:localError];
		while(currentCommit != nil && ![currentCommit.sha isEqualToString:mergeBase.sha]) {
			[commits addObject:currentCommit];
			currentCommit = [enumerator nextObjectWithError:localError];
		}
		
		return commits;
	};
	
	NSArray *localCommits = allCommitsFromSha(self.sha, error);
	NSArray *otherCommits = allCommitsFromSha(otherBranch.sha, error);
	NSMutableArray *uniqueCommits = [localCommits mutableCopy];
	[uniqueCommits removeObjectsInArray:otherCommits];
	return uniqueCommits;
}

- (BOOL)deleteWithError:(NSError **)error {
	BOOL success = [self.reference deleteWithError:error];
	if(success) {
		self.reference = nil;
	}
	
	return success;
}

@end
