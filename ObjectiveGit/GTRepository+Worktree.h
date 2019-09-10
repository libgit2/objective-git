//
//  GTRepository+GTRepository_Worktree.h
//  ObjectiveGitFramework
//
//  Created by Etienne on 25/07/2017.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

#import <ObjectiveGit/ObjectiveGit.h>

@class GTWorktree;

NS_ASSUME_NONNULL_BEGIN

@interface GTRepository (Worktree)

/// Is this the worktree of another repository ?
@property (nonatomic, readonly, getter = isWorktree) BOOL worktree;

/// The URL for the underlying repository's git directory.
/// Returns the same as -gitDirectoryURL if this is	not a worktree.
@property (nonatomic, readonly, strong) NSURL *commonGitDirectoryURL;

+ (instancetype _Nullable)repositoryWithWorktree:(GTWorktree *)worktree error:(NSError **)error;

- (instancetype _Nullable)initWithWorktree:(GTWorktree *)worktree error:(NSError **)error;

- (GTReference * _Nullable)HEADReferenceInWorktreeWithName:(NSString *)name error:(NSError **)error;

- (BOOL)isHEADDetached:(BOOL *)detached inWorktreeWithName:(NSString *)name error:(NSError **)error;

- (BOOL)setWorkingDirectoryURL:(NSURL *)URL updateGitLink:(BOOL)update error:(NSError **)error;

- (NSArray <NSString *> * _Nullable)worktreeNamesWithError:(NSError **)error;

- (GTWorktree * _Nullable)lookupWorktreeWithName:(NSString *)name error:(NSError **)error;

- (GTWorktree * _Nullable)openWorktree:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
