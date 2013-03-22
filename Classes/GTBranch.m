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
@property (nonatomic, strong) GTRepository *repository;
@end

@implementation GTBranch

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> name: %@, shortName: %@, sha: %@, remoteName: %@, repository: %@", NSStringFromClass([self class]), self, self.name, self.shortName, self.sha, self.remoteName, self.repository];
}

- (BOOL)isEqual:(GTBranch *)otherBranch {
	if (otherBranch == self) return YES;
	if (![otherBranch isKindOfClass:self.class]) return NO;

	return [self.name isEqual:otherBranch.name] && [self.sha isEqual:otherBranch.sha];
}

- (NSUInteger)hash {
	return self.name.hash ^ self.sha.hash;
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
	if (self.sha == nil) {
		if (error != NULL) *error = GTReference.invalidReferenceError;
		return nil;
	}

	return (GTCommit *)[self.repository lookupObjectBySha:self.sha objectType:GTObjectTypeCommit error:error];
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
	if (!self.reference.valid) {
		if (error != NULL) *error = GTReference.invalidReferenceError;
		return NO;
	}

	int gitError = git_branch_delete(self.reference.git_reference);
	if(gitError != GIT_OK) {
		if(error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to delete branch."];
		return NO;
	}
	
	self.reference = nil;
	
	return YES;
}

- (GTBranch *)trackingBranchWithError:(NSError **)error success:(BOOL *)success {
	if (self.branchType == GTBranchTypeRemote) {
		if (success != NULL) *success = YES;
		return self;
	}

	if (!self.reference.valid) {
		if (success != NULL) *success = NO;
		if (error != NULL) *error = GTReference.invalidReferenceError;
		return NO;
	}

	git_reference *trackingRef = NULL;
	int gitError = git_branch_tracking(&trackingRef, self.reference.git_reference);

	// GIT_ENOTFOUND means no tracking branch found.
	if (gitError == GIT_ENOTFOUND) {
		if (success != NULL) *success = YES;
		return nil;
	}

	if (gitError != GIT_OK) {
		if (success != NULL) *success = NO;
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:[NSString stringWithFormat:@"Failed to create reference to tracking branch from %@", self]];
		return nil;
	}

	if (trackingRef == NULL) {
		if (success != NULL) *success = NO;
		if (error != NULL) *error = [NSError git_errorFor:gitError withAdditionalDescription:[NSString stringWithFormat:@"Got a NULL remote ref for %@", self]];
		return nil;
	}

	if (success != NULL) *success = YES;

	return [[self class] branchWithReference:[[GTReference alloc] initWithGitReference:trackingRef repository:self.repository] repository:self.repository];
}

- (BOOL)calculateAhead:(size_t *)ahead behind:(size_t *)behind relativeTo:(GTBranch *)branch error:(NSError **)error {
	if (branch == nil) {
		*ahead = 0;
		*behind = 0;
		return YES;
	}

	int errorCode = git_graph_ahead_behind(ahead, behind, self.repository.git_repository, branch.reference.oid, self.reference.oid);
	if (errorCode != GIT_OK && error != NULL) {
		*error = [NSError git_errorFor:errorCode withAdditionalDescription:[NSString stringWithFormat:@"Calculating ahead/behind with %@ to %@", self, branch]];
		return NO;
	}

	return YES;
}

@end
