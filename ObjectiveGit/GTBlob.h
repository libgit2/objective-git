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

NS_ASSUME_NONNULL_BEGIN

@interface GTBlob : GTObject

/// Creates a new blob from the given string.
///
/// This writes data to the repository's object database.
///
/// string     - The string to add. This must not be nil.
/// repository - The repository to put the object in. This must not be nil.
/// error      - Will be set if an error occurs. This may be nil.
///
/// Return a newly created blob object, or nil if an error occurs.
+ (instancetype _Nullable)blobWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError * __autoreleasing *)error;

/// Creates a new blob from the given data.
///
/// This writes data to the repository's object database.
///
/// data       - The data to add. This must not be nil.
/// repository - The repository to put the object in. This must not be nil.
/// error      - Will be set if an error occurs. This may be nil.
///
/// Return a newly created blob object, or nil if an error occurs.
+ (instancetype _Nullable)blobWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError * __autoreleasing *)error;

/// Creates a new blob given an NSURL to a file.
///
/// This copies the data from the file to the repository's object database.
///
/// file       - The NSURL of the file to add. This must not be nil.
/// repository - The repository to put the object in. This must not be nil.
/// error      - Will be set if an error occurs. This may be nil.
///
/// Return a newly created blob object, or nil if an error occurs.
+ (instancetype _Nullable)blobWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError * __autoreleasing *)error;

/// Creates a new blob from the given string.
///
/// Convenience wrapper around `-initWithData:inRepository:error` that converts the string to UTF8 data
///
/// string     - The string to add. This must not be nil.
/// repository - The repository to put the object in. This must not be nil.
/// error      - Will be set if an error occurs. This may be nil.
///
/// Return a newly created blob object, or nil if an error occurs.
- (instancetype _Nullable)initWithString:(NSString *)string inRepository:(GTRepository *)repository error:(NSError * __autoreleasing *)error;

/// Creates a new blob from the passed data.
///
/// This writes data to the repository's object database.
///
/// data       - The data to write. This must not be nil.
/// repository - The repository to put the object in. This must not be nil.
/// error      - Will be set if an error occurs. This may be nil.
///
/// Returns a newly created blob object, or nil if an error occurs.
- (instancetype _Nullable)initWithData:(NSData *)data inRepository:(GTRepository *)repository error:(NSError * __autoreleasing *)error;

/// Creates a new blob from the specified file.
///
/// This copies the data from the file to the repository's object database.
///
/// file       - The file to copy contents from. This must not be nil.
/// repository - The repository to put the object in. This must not be nil.
/// error      - Will be set if an error occurs. This may be nil.
///
/// Returns a newly created blob object, or nil if an error occurs.
- (instancetype _Nullable)initWithFile:(NSURL *)file inRepository:(GTRepository *)repository error:(NSError * __autoreleasing *)error;

/// The underlying `git_object` as a `git_blob` object.
- (git_blob *)git_blob __attribute__((objc_returns_inner_pointer));

- (git_off_t)size;
- (NSString * _Nullable)content;
- (NSData *)data;

/// Attempts to apply the filter list for `path` to the blob.
///
/// path  - The path to use filters from. Must not be nil.
/// error - If not NULL, set to any error that occurs.
///
/// Returns the filtered data, or nil if an error occurs.
- (NSData * _Nullable)applyFiltersForPath:(NSString *)path error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
