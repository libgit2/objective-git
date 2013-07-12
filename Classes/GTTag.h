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


@interface GTTag : GTObject {}

@property (nonatomic, readonly, strong) GTSignature *tagger;

+ (GTTag *)tagInRepository:(GTRepository *)theRepo name:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error;
+ (NSString *)shaByCreatingTagInRepository:(GTRepository *)theRepo name:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error;

// Creates a new lightweight tag.
//
// repository	-	Repository where to store the lightweight tag
// name			-	Name for the tag; this name is validated
//					for consistency. It should also not conflict with an
//					already existing tag name
// target		-	Object to which this tag points. This object
//					must belong to the given repository.
// error		-	Will be filled with a NSError instance on failuer.
//					May be NULL.
//
// Returns YES on success or NO otherwise.
- (BOOL)createLightweightTagInRepository:(GTRepository *)repository name:(NSString *)tagName target:(GTObject *)target error:(NSError **)error;

// The underlying `git_object` as a `git_tag` object.
- (git_tag *)git_tag __attribute__((objc_returns_inner_pointer));

- (NSString *)message;
- (NSString *)name;
- (GTObject *)target;
- (NSString *)targetType;

@end
