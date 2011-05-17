//
//  GTTreeEntry.m
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

#import "GTTreeEntry.h"
#import "GTObject.h"
#import "GTTree.h"
#import "GTLib.h"
#import "GTRepository.h"
#import "NSString+Git.h"
#import "NSError+Git.h"


@interface GTTreeEntry()
@property (nonatomic, assign) const git_tree_entry *entry;
@property (nonatomic, assign) GTTree *tree;
@end

@implementation GTTreeEntry

- (void)dealloc {
	
	self.tree = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark API

@synthesize entry;
@synthesize tree;

- (id)initWithEntry:(const git_tree_entry *)theEntry parentTree:(GTTree *)parent {
	if((self = [super init])) {
		self.entry = theEntry;
		self.tree = parent;
	}
	return self;
}

+ (id)entryWithEntry:(const git_tree_entry *)theEntry parentTree:(GTTree *)parent {
	
	return [[[self alloc] initWithEntry:theEntry parentTree:parent] autorelease];
}

- (NSString *)name {
	
	return [NSString stringWithUTF8String:git_tree_entry_name(self.entry)];
}

- (NSInteger)attributes {
	
	return git_tree_entry_attributes(self.entry);
}

- (NSString *)sha {
	
	return [GTLib convertOidToSha:git_tree_entry_id(self.entry)];
}

- (GTRepository *)repository {
    return self.tree.repository;
}

- (GTObject *)toObjectAndReturnError:(NSError **)error {
	return [GTObject objectWithTreeEntry:self error:error];
}

@end

@implementation GTObject (GTTreeEntry)

+ (id)objectWithTreeEntry:(GTTreeEntry *)treeEntry error:(NSError **)error {
    return [[[self alloc] initWithTreeEntry:treeEntry error:error] autorelease];
}

- (id)initWithTreeEntry:(GTTreeEntry *)treeEntry error:(NSError **)error {
    git_object *obj;
    int gitError = git_tree_entry_2object(&obj, treeEntry.repository.repo, treeEntry.entry);
    if (gitError != GIT_SUCCESS) {
        if (error != NULL) {
            *error = [NSError gitErrorForTreeEntryToObject:gitError];
        }
        [self release];
        return nil;
    }
    
    return [self initWithObj:obj inRepository:treeEntry.repository];
}

@end
