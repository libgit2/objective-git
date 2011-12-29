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

#import "dct_weak.h"
#import "GTBranch.h"
#import "GTReference.h"
#import "GTEnumerator.h"
#import "GTRepository.h"


@interface GTBranch ()
@property (nonatomic, strong) GTReference *reference;
@property (nonatomic, dct_weak) GTRepository *repository;
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
		NSString *remotePath = [[[self class] remoteNamePrefix] stringByAppendingFormat:[NSString stringWithFormat:@"%@/", [self remoteName]]];
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

+ (NSArray *)branchesInRepository:(GTRepository *)repo error:(NSError **)error {
    return [self branchesInRepository:repo withPrefix:[self localNamePrefix] error:error];
}

+ (NSArray *)remoteBranchesInRepository:(GTRepository *)repo error:(NSError **)error {
	static NSArray *unwantedRemoteBranches = nil;
	if(unwantedRemoteBranches == nil) {
		unwantedRemoteBranches = [NSArray arrayWithObjects:@"HEAD", nil];
	}
	
	NSArray *remoteBranches = [self branchesInRepository:repo withPrefix:[self remoteNamePrefix] error:error];
	if(remoteBranches == nil) return nil;
	
	NSMutableArray *filteredList = [NSMutableArray arrayWithCapacity:remoteBranches.count];
	for(GTBranch *branch in remoteBranches) {
		if(![unwantedRemoteBranches containsObject:branch.shortName]) {
			[filteredList addObject:branch];
		}
	}
	
	return filteredList;
}

+ (NSArray *)branchesInRepository:(GTRepository *)repo withPrefix:(NSString *)prefix error:(NSError **)error {
	NSArray *references = [GTReference referenceNamesInRepository:repo error:error];
    if(references == nil) return nil;
	
    NSMutableArray *branches = [NSMutableArray array];
    for(NSString *ref in references) {
        if([ref hasPrefix:prefix]) {
            GTBranch *b = [GTBranch branchWithName:ref repository:repo error:error];
            if(b != nil)
                [branches addObject:b];
        }
    }
    return branches;
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

- (GTBranch *)remoteBranchForRemoteNamed:(NSString *)remote {
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

@end
