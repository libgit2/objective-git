//
//  GTIndexEntry.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
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

#include "git2.h"
#import "GTObject.h"

typedef enum {
	GTIndexEntryStatusUpdated = 0,
	GTIndexEntryStatusRemoved,
	GTIndexEntryStatusNew,
	GTIndexEntryStatusUnchanged,
} GTIndexEntryStatus;


@interface GTIndexEntry : NSObject <GTObject> {}

@property (nonatomic, assign) git_index_entry *git_index_entry;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSDate *modificationDate;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, assign) NSUInteger dev;
@property (nonatomic, assign) NSUInteger ino;
@property (nonatomic, assign) NSUInteger mode;
@property (nonatomic, assign) NSUInteger uid;
@property (nonatomic, assign) NSUInteger gid;
@property (nonatomic, assign) NSUInteger flags;
@property (nonatomic, getter=isStaged, readonly) NSUInteger staged;
@property (nonatomic, getter=isValid, readonly) BOOL valid;
@property (nonatomic, readonly) GTIndexEntryStatus status;
@property (nonatomic, dct_weak) GTRepository *repository;

// Convenience initializers
- (id)initWithEntry:(git_index_entry *)theEntry;
+ (id)indexEntryWithEntry:(git_index_entry *)theEntry;

- (NSString *)sha;
- (BOOL)setSha:(NSString *)theSha error:(NSError **)error;

@end
