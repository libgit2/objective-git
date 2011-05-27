//
//  GTReference.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 3/2/11.
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

typedef enum {
	GTReferenceTypesOid = GIT_REF_OID,				/** A reference which points at an object id */
	GTReferenceTypesSymoblic = GIT_REF_SYMBOLIC,	/** A reference which points at another reference */
	GTReferenceTypesPacked = GIT_REF_PACKED,
	GTReferenceTypesHasPeel = GIT_REF_HAS_PEEL,
	GTReferenceTypesListAll = GTReferenceTypesOid|GTReferenceTypesSymoblic|GTReferenceTypesPacked,
} GTReferenceTypes;

@class GTRepository;

@interface GTReference : NSObject <GTObject> {}

@property (nonatomic, assign) git_reference *ref;
@property (nonatomic, assign) GTRepository *repository;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) const git_oid *oid;

// Convenience initializers
+ (id)referenceByLookingUpReferencedNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error;
- (id)initByLookingUpReferenceNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error;

+ (id)referenceByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)theRepo error:(NSError **)error;
- (id)initByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)theRepo error:(NSError **)error;

+ (id)referenceByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error;
- (id)initByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error;

// List references in a repository
// 
// repository - The GTRepository to list references in
// types - One or more GTReferenceTypes
// error(out) - will be filled if an error occurs
// 
// returns an array of NSStrings holding the names of the references
// returns nil if an error occurred and fills the error parameter
+ (NSArray *)referenceNamesInRepository:(GTRepository *)theRepo types:(GTReferenceTypes)types error:(NSError **)error;

// List all references in a repository
//
// This is a convenience method for listReferencesInRepo: type:GTReferenceTypesListAll error:
// 
// repository - The GTRepository to list references in
// error(out) - will be filled if an error occurs
// 
// returns an array of NSStrings holding the names of the references
// returns nil if an error occurred and fills the error parameter
+ (NSArray *)referenceNamesInRepository:(GTRepository *)theRepo error:(NSError **)error;

- (NSString *)target;
- (BOOL)setTarget:(NSString *)newTarget error:(NSError **)error;
- (NSString *)name;
- (BOOL)setName:(NSString *)newName error:(NSError **)error;

// Pack this reference
//
// error(out) - will be filled if an error occurs
//
// returns YES if the pack was successful
- (BOOL)packAllWithError:(NSError **)error;

// Delete this reference
//
// error(out) - will be filled if an error occurs
//
// returns YES if the delete was successful
- (BOOL)deleteWithError:(NSError **)error;

// Resolve this reference as a symbolic ref
//
// error(out) - will be filled if an error occurs
//
// returns the peeled GTReference or nil if an error occurred.
- (GTReference *)resolvedReferenceWithError:(NSError **)error;

@end
