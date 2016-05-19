//
//  GTNote.h
//  ObjectiveGitFramework
//
//  Created by Slava Karpenko on 5/16/2016.
//
//  The MIT License
//
//  Copyright (c) 2016 Wildbit LLC
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

#import <Foundation/Foundation.h>
#import "git2/oid.h"

@class GTSignature;
@class GTRepository;
@class GTOID;
@class GTObject;

NS_ASSUME_NONNULL_BEGIN

@interface GTNote : NSObject {}

/// The author of the note.
@property (nonatomic, readonly, strong, nullable) GTSignature *author;

/// The committer of the note.
@property (nonatomic, readonly, strong, nullable) GTSignature *committer;

/// Content of the note.
@property (nonatomic, readonly, strong) NSString *note;

@property (nonatomic, readonly, strong) GTObject *target;

/// The underlying `git_note` object.
- (git_note * _Nullable)git_note __attribute__((objc_returns_inner_pointer));

/// These initializers may fail if there's no note attached to the provided oid.
- (nullable instancetype)initWithTargetOID:(GTOID*)oid repository:(GTRepository*)repository ref:(nullable NSString*)ref;
- (nullable instancetype)initWithTargetGitOID:(git_oid*)oid repository:(git_repository *)repository ref:(const char* _Nullable)ref;

@end

NS_ASSUME_NONNULL_END

