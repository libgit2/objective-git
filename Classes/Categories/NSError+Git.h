//
//  NSError+Git.h
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

#import <Cocoa/Cocoa.h>


@interface NSError (Git)

+ (NSError *)gitErrorForInitRepository: (int)code;
+ (NSError *)gitErrorForOpenRepository: (int)code;
+ (NSError *)gitErrorForInitRevWalker: (int)code;
+ (NSError *)gitErrorForPushRevWalker: (int)code;
+ (NSError *)gitErrorForHideRevWalker: (int)code;
+ (NSError *)gitErrorForInitRepoIndex: (int)code;
+ (NSError *)gitErrorForLookupObject: (int)code;
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
+ (NSError *)gitErrorForLookupRef: (int)code;
+ (NSError *)gitErrorForCreateRef: (int)code;
+ (NSError *)gitErrorForSetRefTarget: (int)code;
+ (NSError *)gitErrorForPackAllRefs: (int)code;
+ (NSError *)gitErrorForDeleteRef: (int)code;
+ (NSError *)gitErrorForResloveRef: (int)code;
+ (NSError *)gitErrorForRenameRef: (int)code;
+ (NSError *)gitErrorForListAllRefs: (int)code;
+ (NSError *)gitErrorForNoBlockProvided;

+ (NSError *)gitErrorFor:(int)code withDescription:(NSString *)desc;

@end
