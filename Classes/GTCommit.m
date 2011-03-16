//
//  GTCommit.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
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

#import "GTCommit.h"
#import "GTSignature.h"
#import "GTTree.h"
#import "NSString+Git.h"
#import "NSError+Git.h"
#import "GTRepository.h"


@implementation GTCommit

- (void)dealloc {
	
	// All these properties pass through to underlying C object
	// there is nothing to release here
	//self.message = nil;
	//self.author = nil;
	//self.committer = nil;
	//self.tree = nil;
	[super dealloc];
}

- (git_commit *)commit {
	
	return (git_commit *)self.object;
}

#pragma mark -
#pragma mark API 

@synthesize commit;
@synthesize message;
@synthesize messageShort;
@synthesize date;
@synthesize author;
@synthesize committer;
@synthesize tree;
@synthesize parents;

- (id)initInRepo:(GTRepository *)theRepo error:(NSError **)error {
	
	if((self = [super init])) {
		self.repo = theRepo;
		self.object = [GTObject getNewObjectInRepo:self.repo.repo type:GIT_OBJ_COMMIT error:error];
		if(self.object == nil)return nil;
	}
	return self;
}

- (NSString *)message {

	const char *s = git_commit_message(self.commit);
	return [NSString stringForUTF8String:s];
}
- (void)setMessage:(NSString *)m {
	
	git_commit_set_message(self.commit, [NSString utf8StringForString:m]);
}

- (NSString *)messageShort {
	
	const char *s = git_commit_message_short(self.commit);
	return [NSString stringForUTF8String:s];
}

- (NSDate *)date {
	
	time_t t = git_commit_time(self.commit);
	return [NSDate dateWithTimeIntervalSince1970:t];
}

- (GTSignature *)author {

	const git_signature *s = git_commit_author(self.commit);
	return [GTSignature signatureWithSignature:(git_signature *)s];
}
- (void)setAuthor:(GTSignature *)a {
	
	git_commit_set_author(self.commit, a.signature);
}

- (GTSignature *)committer {
	
	const git_signature *s = git_commit_committer(self.commit);
	return [GTSignature signatureWithSignature:(git_signature *)s];
}
- (void)setCommitter:(GTSignature *)c {
	
	git_commit_set_committer(self.commit, c.signature);
}

- (GTTree *)tree {

	git_tree *t;
	
	int gitError = git_commit_tree(&t, self.commit);
	if(gitError != GIT_SUCCESS){
		// todo: might want to return this error (and change method signature)
		GTLog("Failed to get tree with error code: %d", gitError);
		return nil;
	}
	return (GTTree *)[GTObject objectInRepo:self.repo withObject:(git_object *)t];
}
- (void)setTree:(GTTree *)t {
	
	git_commit_set_tree(self.commit, t.tree);
}

- (NSArray *)parents {
	
	if(parents == nil){
		NSMutableArray *rents = [[[NSMutableArray alloc] init] autorelease];
		
		// todo: do we care if a call to git_commit_parent fails?
		git_commit *parent;
		for(int i=0; git_commit_parent(&parent, self.commit, i) == GIT_SUCCESS; i++) {
			[rents addObject:(GTCommit *)[GTObject objectInRepo:self.repo withObject:(git_object *)parent]];
		}
		
		parents = [NSArray arrayWithArray:rents];
	}
	return parents;
}

@end
