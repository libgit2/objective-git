//
//  NSError+Git.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/17/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSError (Git)

+ (NSError *)gitErrorForInitRepository: (int)code;
+ (NSError *)gitErrorForOpenRepository: (int)code;
+ (NSError *)gitErrorForInitRevWalker: (int)code;
+ (NSError *)gitErrorForInitRepoIndex: (int)code;
+ (NSError *)gitErrorForLookupSha: (int)code;
+ (NSError *)gitErrorForMkStr: (int)code;
+ (NSError *)gitErrorForAddTreeEntry: (int)code;
+ (NSError *)gitErrorForNewObject: (int)code;
+ (NSError *)gitErrorForWriteObject: (int)code;
+ (NSError *)gitErrorForRawRead: (int)code;
+ (NSError *)gitErrorForHashObject: (int)code;
+ (NSError *)gitErrorForWriteObjectToDb: (int)code;
+ (NSError *)gitErrorForTreeEntryToObject: (int)code;
+ (NSError *)gitErrorForInitIndex: (int)code;
+ (NSError *)gitErrorForReadIndex: (int)code;
+ (NSError *)gitErrorForIndexStageValue;
+ (NSError *)gitErrorForAddEntryToIndex: (int)code;
+ (NSError *)gitErrorForWriteIndex: (int)code;

@end
