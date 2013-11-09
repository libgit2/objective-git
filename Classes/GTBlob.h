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


@interface GTBlob : GTObject

// Convenience class methods
+ (instancetype)blobWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError **)error;
+ (instancetype)blobWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError **)error;
+ (instancetype)blobWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError **)error;

// Convenience wrapper around `-initWithData:inRepository:error` that converts the string to UTF8 data
- (instancetype)initWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError **)error;

// Creates a new blob from the passed data.
//
// This writes data to the repository's object database.
//
// data       - The data to write.
// repository - The repository to put the object in.
// error      - Will be set if an error occurs.
//
// Returns a newly created blob object, or nil if an error occurs.
- (instancetype)initWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError **)error;

// Creates a new blob from the specified file.
//
// This copies the data from the file to the repository's object database.
//
// data       - The file to copy contents from.
// repository - The repository to put the object in.
// error      - Will be set if an error occurs.
//
// Returns a newly created blob object, or nil if an error occurs.
- (instancetype)initWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError **)error;

// The underlying `git_object` as a `git_blob` object.
- (git_blob *)git_blob __attribute__((objc_returns_inner_pointer));

- (git_off_t)size;
- (NSString *)content;
- (NSData *)data;

@end
