//
//  GTRepository.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/17/11.
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

#import <git2.h>

@class GTWalker;
@class GTObject;
@class GTRawObject;
@class GTCommit;
@class GTIndex;

@interface GTRepository : NSObject {}

@property (nonatomic, assign) git_repository *repo;
@property (nonatomic, retain) NSURL *fileUrl;
@property (nonatomic, retain) GTWalker *walker;
@property (nonatomic, retain) GTIndex *index;

+ (id)repoByOpeningRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error;
+ (id)repoByCreatingRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error;
- (id)initByOpeningRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error;
- (id)initByCreatingRepositoryInDirectory:(NSURL *)localFileUrl error:(NSError **)error;

+ (NSString *)hash:(GTRawObject *)rawObj error:(NSError **)error;

- (GTObject *)lookup:(NSString *)sha error:(NSError **)error;
- (BOOL)exists:(NSString *)sha;
- (BOOL)hasObject:(NSString *)sha;
- (GTRawObject *)rawRead:(const git_oid *)oid error:(NSError **)error;
- (GTRawObject *)read:(NSString *)sha error:(NSError **)error;
- (NSString *)write:(GTRawObject *)rawObj error:(NSError **)error;
- (void)walk:(NSString *)sha sorting:(unsigned int)sortMode error:(NSError **)error block:(void (^)(GTCommit *commit))block;
- (void)walk:(NSString *)sha error:(NSError **)error block:(void (^)(GTCommit *commit))block;
- (void)setupIndexAndReturnError:(NSError **)error;

@end
