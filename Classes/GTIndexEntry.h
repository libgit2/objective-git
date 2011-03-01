//
//  GTIndexEntry.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <git2.h>


@interface GTIndexEntry : NSObject {

}

@property (nonatomic, assign) git_index_entry *entry;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *sha;
@property (nonatomic, copy) NSDate *mTime;
@property (nonatomic, copy) NSDate *cTime;
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, assign) NSUInteger dev;
@property (nonatomic, assign) NSUInteger ino;
@property (nonatomic, assign) NSUInteger mode;
@property (nonatomic, assign) NSUInteger uid;
@property (nonatomic, assign) NSUInteger gid;
@property (nonatomic, assign) NSUInteger flags;
@property (nonatomic, assign) NSUInteger stage;
@property (nonatomic, assign, readonly) BOOL isValid;

+ (id)indexEntryWithEntry:(git_index_entry *)theEntry;
- (id)initWithEntry:(git_index_entry *)theEntry;

@end
