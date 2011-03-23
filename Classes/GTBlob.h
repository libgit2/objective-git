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

#import <git2.h>
#import "GTObject.h"


@interface GTBlob : GTObject {}

// Convenience initializers
// 
// These call the associated createInRepo: methods, but then lookup the newly 
// created blob in the repo and return it
+ (GTBlob *)blobInRepo:(GTRepository *)theRepo content:(NSString *)content error:(NSError **)error;
+ (GTBlob *)blobInRepo:(GTRepository *)theRepo data:(NSData *)data error:(NSError **)error;
+ (GTBlob *)blobInRepo:(GTRepository *)theRepo file:(NSURL *)file error:(NSError **)error;

// Create a blob in the specified repository
//
// returns the sha1 of the created blob or nil if an error occurred
+ (NSString *)createInRepo:(GTRepository *)theRepo content:(NSString *)content error:(NSError **)error;
+ (NSString *)createInRepo:(GTRepository *)theRepo data:(NSData *)data error:(NSError **)error;
+ (NSString *)createInRepo:(GTRepository *)theRepo file:(NSURL *)file error:(NSError **)error;

- (NSInteger)size;
- (NSString *)content;

@end
