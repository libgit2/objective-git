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
@property (nonatomic, readonly, strong) GTSignature * _Nullable author;

/// The committer of the note.
@property (nonatomic, readonly, strong) GTSignature * _Nullable committer;

/// Content of the note.
@property (nonatomic, readonly, strong) NSString *note;

@property (nonatomic, readonly, strong) GTObject *target;

/// The underlying `git_note` object.
- (git_note *)git_note __attribute__((objc_returns_inner_pointer));

/// Create a note with target OID in the given repository.
///
/// oid           - OID of the target to attach to
/// repository    - Repository containing the target OID refers to
/// referenceName - Name for the notes reference in the repo, or nil for default ("refs/notes/commits")
/// error         - Will be filled with a NSError object in case of error.
///                 May be NULL.
///
/// Returns initialized GTNote instance or nil on failure (error will be populated, if passed).
- (instancetype _Nullable)initWithTargetOID:(GTOID *)oid repository:(GTRepository *)repository referenceName:(NSString * _Nullable)referenceName error:(NSError **)error;

/// Create a note with target libgit2 oid in the given repository.
///
/// oid           - git_oid of the target to attach to
/// repository    - Repository containing the target OID refers to
/// referenceName - Name for the notes reference in the repo, or NULL for default ("refs/notes/commits")
///
/// Returns initialized GTNote instance or nil on failure.
- (instancetype _Nullable)initWithTargetGitOID:(git_oid *)oid repository:(git_repository *)repository referenceName:(const char * _Nullable)referenceName error:(NSError **)error NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;


/// Return a default reference name (that is used if you pass nil to any referenceName parameter)
///
/// repository    - Repository for which to get the default notes reference name.
/// error         - Will be filled with a git error code in case of error.
///                 May be NULL.
///
/// Returns default reference name (usually "refs/notes/commits").
+ (NSString * _Nullable)defaultReferenceNameForRepository:(GTRepository *)repository error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END

