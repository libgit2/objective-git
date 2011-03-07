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

@interface GTBranch ()
@property (nonatomic, retain) GTReference *reference;
@property (nonatomic, retain) GTRepository *repository;

+ (NSString *)defaultBranchRefPath;
@end


@implementation GTBranch

- (void)dealloc {
	self.reference = nil;
	self.repository = nil;
	
	[super dealloc];
}


#pragma mark API

@synthesize reference;
@synthesize repository;

+ (NSString *)defaultBranchRefPath {
	return @"refs/heads/";
}

- (id)initWithName:(NSString *)branchName repository:(GTRepository *)repo error:(NSError **)error {
	self = [super init];
	if(self == nil) return nil;
	
	self.reference = [GTReference referenceByLookingUpRef:[NSString stringWithFormat:@"%@%@", [[self class] defaultBranchRefPath], branchName] inRepo:repo error:error];
	if(self.reference == nil) return nil;
	
	self.repository = repo;
	
	return self;
}

- (NSString *)name {
	return [self.reference.name stringByReplacingOccurrencesOfString:[[self class] defaultBranchRefPath] withString:@""];
}

- (GTWalker *)walkerWithOptions:(GTWalkerOptions)options error:(NSError **)error {
	GTWalker *walker = [[GTWalker alloc] initWithRepository:self.repository error:error];
	[walker setSortingOptions:options];
	[walker push:[GTLib hexFromOid:self.reference.oid] error:error];
	return walker;
}

- (GTCommit *)mostRecentCommitWithError:(NSError **)error {
	GTWalker *walker = [self walkerWithOptions:GTWalkerOptionsTopologicalSort error:error];
	if(walker == nil) {
		return nil;
	}
	
	return [walker next];
}

@end
