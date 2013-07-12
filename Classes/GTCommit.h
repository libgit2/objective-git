//
//  GTCommit.h
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


#import "GTObject.h"

@class GTSignature;
@class GTTree;
@class GTOID;

@interface GTCommit : GTObject {}

@property (nonatomic, readonly, strong) GTSignature *author;
@property (nonatomic, readonly, strong) GTSignature *committer;
@property (nonatomic, readonly, copy) NSArray *parents;
@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly) NSString *messageDetails;
@property (nonatomic, readonly) NSString *messageSummary;
@property (nonatomic, readonly) NSDate *commitDate;
@property (nonatomic, readonly) NSTimeZone *commitTimeZone;
@property (nonatomic, readonly) GTTree *tree;

+ (GTCommit *)commitInRepository:(GTRepository *)theRepo updateRefNamed:(NSString *)refName author:(GTSignature *)authorSig committer:(GTSignature *)committerSig message:(NSString *)newMessage tree:(GTTree *)theTree parents:(NSArray *)theParents error:(NSError **)error;

// Creates a new commit using OIDByCreatingCommitInRepsotory:updatedRefName:author:commiter:message:tree:parents:error:
// and returns it's SHA as a string.
+ (NSString *)shaByCreatingCommitInRepository:(GTRepository *)theRepo updateRefNamed:(NSString *)refName author:(GTSignature *)authorSig committer:(GTSignature *)committerSig message:(NSString *)newMessage tree:(GTTree *)theTree parents:(NSArray *)theParents error:(NSError **)error;

// Creates a new commit
//
// theRepo      - the repository to add the commit to
// refName      - If not nil, name of the reference that
//                will be updated to point to this commit. If the reference
//                is not direct, it will be resolved to a direct reference.
//                Use @"HEAD" to update the HEAD of the current branch and
//                make it point to this commit. If the reference doesn't
//                exist yet, it will be created.
// authorSig    - Signature with author and author time of commit
// committerSig - Signature with committer and commit time of commit
// newMessage   - Full message of this commit
// theTree      - An instance of a `GTTree` object that will
//                be used as the tree for the commit. This tree object must
//                also be owned by the given repository.
// theParents   - Array of GTCommit objects that will be used as the parents
//                for this commit. This array may be nil. All the
//                given commits must be owned by the given repository.
// error        - Will be filled with a NSError object if an error occurs.
//                May be NULL.
//
// Returns the object ID of the newly created commit or nil on error.
+ (GTOID *)OIDByCreatingCommitInRepository:(GTRepository *)theRepo updateRefNamed:(NSString *)refName author:(GTSignature *)authorSig committer:(GTSignature *)committerSig message:(NSString *)newMessage tree:(GTTree *)theTree parents:(NSArray *)theParents error:(NSError **)error;

// The underlying `git_object` as a `git_commit` object.
- (git_commit *)git_commit __attribute__((objc_returns_inner_pointer));

@end
