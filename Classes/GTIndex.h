//
//  GTIndex.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>

@class GTIndexEntry;

@interface GTIndex : NSObject {}

@property (nonatomic, assign) git_index *index;
@property (nonatomic, copy) NSURL *path;
@property (nonatomic, assign) NSInteger entryCount;

+ (id)indexWithPath:(NSURL *)localFileUrl error:(NSError **)error;
- (id)initWithPath:(NSURL *)localFileUrl error:(NSError **)error;
+ (id)indexWithIndex:(git_index *)theIndex;
- (id)initWithGitIndex:(git_index *)theIndex;
- (void)refreshAndReturnError:(NSError **)error;
- (void)clear;
- (GTIndexEntry *)getEntryAtIndex:(NSInteger)theIndex;
- (GTIndexEntry *)getEntryWithName:(NSString *)name;
- (void)addEntry:(GTIndexEntry *)entry error:(NSError **)error;
- (void)addFile:(NSString *)file error:(NSError **)error;
- (void)writeAndReturnError:(NSError **)error;

@end
