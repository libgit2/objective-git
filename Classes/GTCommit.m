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
#import "NSError+Git.h"
#import "GTRepository.h"
#import "NSString+Git.h"
#import "NSDate+GTTimeAdditions.h"

@interface GTCommit ()
@property (nonatomic, strong) GTSignature *author;
@property (nonatomic, strong) GTSignature *committer;
@property (nonatomic, copy) NSArray *parents;
@end


@implementation GTCommit

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> author: %@, message: %@", NSStringFromClass([self class]), self, self.author, [self message]];
}

- (git_commit *)git_commit {
	return (git_commit *) self.git_object;
}

#pragma mark API

+ (GTCommit *)commitInRepository:(GTRepository *)theRepo updateRefNamed:(NSString *)refName author:(GTSignature *)authorSig committer:(GTSignature *)committerSig message:(NSString *)newMessage tree:(GTTree *)theTree parents:(NSArray *)theParents error:(NSError **)error {
	NSString *sha = [GTCommit shaByCreatingCommitInRepository:theRepo updateRefNamed:refName author:authorSig committer:committerSig message:newMessage tree:theTree parents:theParents error:error];
	return sha ? (GTCommit *)[theRepo lookupObjectBySha:sha objectType:GTObjectTypeCommit error:error] : nil;
}

+ (NSString *)shaByCreatingCommitInRepository:(GTRepository *)theRepo updateRefNamed:(NSString *)refName author:(GTSignature *)authorSig committer:(GTSignature *)committerSig message:(NSString *)newMessage tree:(GTTree *)theTree parents:(NSArray *)theParents error:(NSError **)error {
	NSUInteger count = theParents ? theParents.count : 0;
	const git_commit **parentCommits = NULL;
	if(count > 0) {
		parentCommits = calloc(count, sizeof(git_commit *));
		for (NSUInteger i = 0; i < count; i++){
			parentCommits[i] = ((GTCommit *)[theParents objectAtIndex:i]).git_commit;
		}
	}
	
	git_oid oid;
	int gitError = git_commit_create(
									 &oid, 
									 theRepo.git_repository, 
									 refName ? [refName UTF8String] : NULL, 
									 authorSig.git_signature, 
									 committerSig.git_signature, 
									 NULL,
									 newMessage ? [newMessage UTF8String] : "",
									 theTree.git_tree, 
									 (int)count, 
									 parentCommits);
	if(gitError < GIT_OK) {
		if(parentCommits != NULL) free(parentCommits);
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to create commit in repository"];
		return nil;
	}
	if(parentCommits != NULL) free(parentCommits);
	
	return [NSString git_stringWithOid:&oid];
}

- (NSString *)message {
	const char *s = git_commit_message(self.git_commit);
	if(s == NULL) return nil;
	return [NSString stringWithUTF8String:s];
}

- (NSString *)messageDetails {
	NSArray *lines = [self.message componentsSeparatedByString:@"\n"];
	if(lines.count < 2) return @"";
	
	NSMutableString *result = [NSMutableString string];
	NSString *secondLine = [(NSString *)[lines objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if(secondLine.length != 0) {
		[result appendFormat:@"%@\n", secondLine];
	}
	
	for(NSUInteger i = 2; i < lines.count; i++) {
		[result appendFormat:@"%@\n", [[lines objectAtIndex:i] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	}
	
	return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)messageSummary {
	NSArray *messageComponents = [self.message componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	return messageComponents.count > 0 ? [messageComponents objectAtIndex:0] : @"";
}

- (git_time)commitTime {
	return (git_time){ .time = git_commit_time(self.git_commit), .offset = git_commit_time_offset(self.git_commit) };
}

- (NSDate *)commitDate {
	return [NSDate gt_dateFromGitTime:self.commitTime];
}

- (NSTimeZone *)commitTimeZone {
	return [NSTimeZone gt_timeZoneFromGitTime:self.commitTime];
}

- (GTSignature *)author {
	if (_author == nil) {
		_author = [GTSignature signatureWithSignature:(git_signature *)git_commit_author(self.git_commit)];
	}
	
	return _author;
}

- (GTSignature *)committer {
	if (_committer == nil) {
		_committer = [GTSignature signatureWithSignature:(git_signature *)git_commit_committer(self.git_commit)];
	}
	return _committer;
}

- (GTTree *)tree {
	git_tree *tree = NULL;
	int gitError = git_commit_tree(&tree, self.git_commit);
	if (gitError < GIT_OK) {
		// todo: might want to return this error (and change method signature)
		GTLog("Failed to get tree with error code: %d", gitError);
		return nil;
	}
	
	return (GTTree *)[GTObject objectWithObj:(git_object *)tree inRepository:self.repository];
}

- (NSArray *)parents {
	if(_parents == nil) {
		unsigned int numberOfParents = git_commit_parentcount(self.git_commit);
		NSMutableArray *parents = [NSMutableArray arrayWithCapacity:numberOfParents];
		
		for (unsigned int i = 0; i < numberOfParents; i++) {
			git_commit *parent = NULL;
			int parentResult = git_commit_parent(&parent, self.git_commit, i);
			if (parentResult != GIT_OK) continue;

			[parents addObject:(GTCommit *)[GTObject objectWithObj:(git_object *)parent inRepository:self.repository]];
		}
		
		_parents = [parents copy];
	}
	
	return _parents;
}

@end
