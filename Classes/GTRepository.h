//
//  GTRepository.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/17/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
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
