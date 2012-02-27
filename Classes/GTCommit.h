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


@interface GTCommit : GTObject {}

@property (nonatomic, readonly) git_commit *git_commit;
@property (nonatomic, readonly, strong) GTSignature *author;
@property (nonatomic, readonly, strong) GTSignature *committer;
@property (nonatomic, readonly, copy) NSArray *parents;
@property (nonatomic, readonly) NSString *message;
@property (nonatomic, readonly) NSString *messageDetails;
@property (nonatomic, readonly) NSString *messageSummary;
@property (nonatomic, readonly) NSDate *commitDate;
@property (nonatomic, readonly) GTTree *tree;

+ (GTCommit *)commitInRepository:(GTRepository *)theRepo updateRefNamed:(NSString *)refName author:(GTSignature *)authorSig committer:(GTSignature *)committerSig message:(NSString *)newMessage tree:(GTTree *)theTree parents:(NSArray *)theParents error:(NSError **)error;

+ (NSString *)shaByCreatingCommitInRepository:(GTRepository *)theRepo updateRefNamed:(NSString *)refName author:(GTSignature *)authorSig committer:(GTSignature *)committerSig message:(NSString *)newMessage tree:(GTTree *)theTree parents:(NSArray *)theParents error:(NSError **)error;

@end
