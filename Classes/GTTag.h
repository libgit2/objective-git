//
//  GTTag.h
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

#import "GTObject.h"

@class GTSignature;
@class GTRepository;
@class GTReference;

@interface GTTag : GTObject {}

// The author of the tag.
@property (nonatomic, readonly, strong) GTSignature *tagger;

// The description given when the tag was created.
@property (nonatomic, readonly, strong) NSString *message;

// The label of the tag. Generally a version number.
@property (nonatomic, readonly, strong) NSString *name;

// The 'tagged' object.
@property (nonatomic, readonly, strong) GTObject *target;

// The type of the 'tagged' object.
@property (nonatomic, readonly) GTObjectType targetType;

// Creates a tag in a repository.
//
// tagName      - Name for the tag; this name is validated for consistency.
//                If `force` is `NO`, it should also not conflict with an
//                already existing tag name.
// targetObject - The object the tag should point to. It must belong to `repository`.
// message      - The message attached to the tag.
// tagger       - Signature of the tagger for this tag, and of the tagging time
// force        - If YES, an underlying duplicate reference would be deleted.
// repository   - The repository to create the tag in.
// error        - This optional pointer will be set to a NSError instance if
//                the tag's creation fails.
//
// Returns a newly created tag, or nil if the tag creation failed.
+ (instancetype)tagByCreatingTagNamed:(NSString *)tagName target:(GTObject *)targetObject message:(NSString *)message tagger:(GTSignature *)tagger force:(BOOL)force inRepository:(GTRepository *)repository error:(NSError **)error;

// Creates a lightweight tag in a repository.
//
// tagName      - Name for the tag; this name is validated for consistency.
//                If `force` is `NO`, it should also not conflict with an
//                already existing tag name.
// targetObject - The object the tag should point to. It must belong to `repository`.
// force        - If YES, an underlying duplicate reference would be deleted.
// repository   - The repository to create the tag in.
// error        - This optional pointer will be set to a NSError instance if
//                the tag's creation fails.
//
// Returns the reference underlying the new tag, or nil if the tag creation failed.
+ (GTReference *)tagByCreatingLightweightTagNamed:(NSString *)tagName target:(GTObject *)targetObject force:(BOOL)force inRepository:(GTRepository *)repository error:(NSError **)error;

// Recursively peel a tag until a non tag GTObject is found
//
// error - Will be filled with a NSError object on failure.
//         May be NULL.
//
// Returns the found object or nil on error.
- (id)objectByPeelingTagError:(NSError **)error;

// Delete the receiver.
- (BOOL)delete:(NSError **)error;

// The underlying `git_object` as a `git_tag` object.
- (git_tag *)git_tag __attribute__((objc_returns_inner_pointer));

@end
