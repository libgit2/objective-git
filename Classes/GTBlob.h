//
//  GTBlob.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/25/11.
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


@interface GTBlob : GTObject {}

@property (nonatomic, readonly) git_blob *git_blob;

+ (id)blobWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError **)error;
+ (id)blobWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError **)error;
+ (id)blobWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError **)error;

- (id)initWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError **)error;
- (id)initWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError **)error;
- (id)initWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError **)error;

- (size_t)size;
- (NSString *)content;
- (NSData *)data;

@end
