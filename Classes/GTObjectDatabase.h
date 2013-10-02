//
//  GTObjectDatabase.h
//  ObjectiveGitFramework
//
//  Created by Dave DeLong on 5/17/2011.
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

@class GTOID;

@interface GTObjectDatabase : NSObject

@property (nonatomic, readonly, strong) GTRepository *repository;

// Initializes the object database with the given repository.
//
// repo  - The repository from which the object database should be created.
//         Cannot be nil.
// error - The error if one occurred.
//
// Returns the initialized object.
- (id)initWithRepository:(GTRepository *)repo error:(NSError **)error;

// The underlying `git_odb` object.
- (git_odb *)git_odb __attribute__((objc_returns_inner_pointer));

- (GTOdbObject *)objectWithOID:(GTOID *)OID error:(NSError **)error;
- (GTOdbObject *)objectWithSHA:(NSString *)SHA error:(NSError **)error;

// Writes the data into the object database.
//
// data  - The data to write. Cannot be nil.
// type  - The type of object to create with the data.
// error - The error if one occurred.
//
// Returns the OID for the object which was written, or nil if an error
// occurred.
- (GTOID *)writeData:(NSData *)data type:(GTObjectType)type error:(NSError **)error;

- (BOOL)containsObjectWithSHA:(NSString *)SHA error:(NSError **)error;

// Checks if the object database contains an object with a given OID.
//
// oid - Object ID to check
//
// Returns YES if the object exists or NO otherwise.
- (BOOL)containsObjectWithOID:(GTOID *)oid;

@end
