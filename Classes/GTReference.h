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
	GTReferenceErrorCodeInvalidReference = -4,
} GTReferenceErrorCode;

typedef enum {
	GTReferenceTypesOid = GIT_REF_OID,				/** A reference which points at an object id */
	GTReferenceTypesSymoblic = GIT_REF_SYMBOLIC,	/** A reference which points at another reference */
	GTReferenceTypesPacked = GIT_REF_PACKED,
	GTReferenceTypesHasPeel = GIT_REF_HAS_PEEL,
	GTReferenceTypesListAll = GIT_REF_LISTALL,
} GTReferenceTypes;

@class GTRepository;


@interface GTReference : NSObject <GTObject> {}

@property (nonatomic, assign) git_reference *git_reference;
@property (nonatomic, dct_weak) GTRepository *repository;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) const git_oid *oid;
@property (nonatomic, readonly, getter=isValid) BOOL valid;

// Convenience initializers
+ (id)referenceByLookingUpReferencedNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error;
- (id)initByLookingUpReferenceNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error;

+ (id)referenceByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)theRepo error:(NSError **)error;
- (id)initByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)theRepo error:(NSError **)error;

+ (id)referenceByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error;
- (id)initByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error;

- (NSString *)target;
- (BOOL)setTarget:(NSString *)newTarget error:(NSError **)error;
- (NSString *)name;
- (BOOL)setName:(NSString *)newName error:(NSError **)error;

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

// Reload the reference from disk. Note that if reloading fails, the underlying `git_reference` will be invalidated and NULL'd.
//
// error(out) - will be filled if an error occurs
//
// returns YES if the reload was successful, NO otherwise.
- (BOOL)reloadWithError:(NSError **)error;

@end
