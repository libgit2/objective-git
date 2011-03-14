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
#import "GTLib.h"
#import "GTWalker.h"
#import "GTRepository.h"


@interface GTBranch ()
@property (nonatomic, assign) GTReference *reference;
@property (nonatomic, assign) GTRepository *repository;

+ (NSString *)defaultBranchRefPath;
@end


@implementation GTBranch

+ (NSString *)defaultBranchRefPath {
	return @"refs/heads/";
}

- (BOOL)isEqual:(id)otherObject {
	
	if(![otherObject isKindOfClass:[GTBranch class]]) {
		return NO;
	}
	
	GTBranch *otherBranch = otherObject;
	
	return [self.reference.name isEqualToString:otherBranch.reference.name];
}

- (NSUInteger)hash {
	
	return [self.name hash];
}

- (NSString *)description {
	
	return [NSString stringWithFormat:@"<%@: %p>: name: %@, sha: %@", NSStringFromClass([self class]), self, self.name, self.sha];
}

#pragma mark -
#pragma mark API

@synthesize reference;
@synthesize repository;

- (id)initWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error {
	
	if((self = [super init])) {
		self.reference = [GTReference referenceByLookingUpRef:branchName inRepo:repo error:error];
		if(self.reference == nil) return nil;
		
		self.repository = repo;
	}
	return self;
}
+ (id)branchWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error {
	
	return [[[self alloc] initWithName:branchName repository:repo error:error] autorelease];
}

- (id)initWithShortName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error {
	
	if((self = [super init])) {
		self.reference = [GTReference referenceByLookingUpRef:[NSString stringWithFormat:@"%@%@", [[self class] defaultBranchRefPath], branchName] inRepo:repo error:error];
		if(self.reference == nil) return nil;
		
		self.repository = repo;
	}
	return self;
}
+ (id)branchWithShortName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error {
	
	return [[[self alloc] initWithShortName:branchName repository:repo error:error] autorelease];
}

- (id)initWithReference:(GTReference *)ref repository:(GTRepository *)repo {
	
	if((self = [super init])) {
		self.reference = ref;
		self.repository = repo;
	}
	return self;
}
+ (id)branchWithReference:(GTReference *)ref repository:(GTRepository *)repo {
	
	return [[[self alloc] initWithReference:ref repository:repo] autorelease];
}

+ (id)branchFromCurrentBranchInRepository:(GTRepository *)repo error:(NSError **)error {
	
	GTReference *head = [repo headAndReturnError:error];
	if (head == nil) return nil;
	
	return [self branchWithReference:head repository:repo];
}

- (NSString *)name {
	
	return self.reference.name;		
}

- (NSString *)shortName {
	
	return [self.reference.name stringByReplacingOccurrencesOfString:[[self class] defaultBranchRefPath] withString:@""];		
}

- (NSString *)sha {
	
	return self.reference.target;
}

- (GTCommit *)mostRecentCommitWithError:(NSError **)error {
	
	//[self.repository.walker reset];
	[self.repository.walker setSortingOptions:GTWalkerOptionsTopologicalSort];
	BOOL success = [self.repository.walker push:self.reference.target error:error];
	if(!success) return nil;
	
	return [self.repository.walker next];
}

+ (NSArray *)listAllBranchesInRepository:(GTRepository *)repo error:(NSError **)error {

    NSArray *references = [GTReference listAllReferenceNamesInRepo:repo error:error];
    if(references == nil) return nil;

    NSMutableArray *branches = [NSMutableArray array];
    for(NSString *ref in references) {
        if([ref hasPrefix:@"refs/heads/"]){
            GTBranch *b = [GTBranch branchWithName:ref repository:repo error:error];
            if(b != nil)
                [branches addObject:b];
        }
    }
    return branches;
}

@end
