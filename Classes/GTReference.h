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

@class GTOID;
@class GTReflog;

typedef enum {
	GTReferenceErrorCodeInvalidReference = -4,
} GTReferenceErrorCode;

typedef enum {
	GTReferenceTypesOid = GIT_REF_OID,				/* A reference which points at an object id */
	GTReferenceTypesSymbolic = GIT_REF_SYMBOLIC,	/* A reference which points at another reference */
	GTReferenceTypesListAll = GIT_REF_LISTALL,
} GTReferenceTypes;

@class GTRepository;

/**
 * A reference
 */
@interface GTReference : NSObject

/** @name Properties */

/// The repository this reference belongs to
@property (nonatomic, readonly, strong) GTRepository *repository;

/// The type of the reference
@property (nonatomic, readonly) NSString *type;

/// The underlying git_oid object
@property (nonatomic, readonly) const git_oid *git_oid;

/// The underlying GTOID object
@property (nonatomic, strong, readonly) GTOID *OID;

/// Whether this is a remote-tracking branch.
@property (nonatomic, readonly, getter = isRemote) BOOL remote;

/// The reflog for the reference.
@property (nonatomic, readonly, strong) GTReflog *reflog;

/// The name of the reference.
@property (nonatomic, readonly, copy) NSString *name;

/// The target to which the reference points.
@property (nonatomic, readonly, copy) NSString *target;

/// The underlying `git_reference` object.
- (git_reference *)git_reference __attribute__((objc_returns_inner_pointer));

/** @name Convenience initializers */

/**
 * Lookups a reference in a given repository
 *
 * This can be used to resolve a reference from its name
 *
 * @param refName	The reference name to look up
 * @param theRepo	The repository to search in
 * @param error		An error if one occurred
 *
 * @return Returns a new reference for the name passed, or nil if the reference couldn't be resolved
 */
+ (id)referenceByLookingUpReferencedNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error;
- (id)initByLookingUpReferenceNamed:(NSString *)refName inRepository:(GTRepository *)theRepo error:(NSError **)error;

+ (id)referenceByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)theRepo error:(NSError **)error;
- (id)initByCreatingReferenceNamed:(NSString *)refName fromReferenceTarget:(NSString *)target inRepository:(GTRepository *)theRepo error:(NSError **)error;

+ (id)referenceByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error;
- (id)initByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error;

- (id)initWithGitReference:(git_reference *)ref repository:(GTRepository *)repository;

/** @name Reference manipulation */

/**
 * Updates the on-disk reference to point to the target and returns the updated
 * reference.
 *
 * Note that this does *not* change the receiver's target.
 *
 * @param newTarget The target for the new reference. Cannot be nil.
 * @param error		The error if one occurred.
 *
 * @return Returns the updated reference, or nil if an error occurred.
 */
- (GTReference *)referenceByUpdatingTarget:(NSString *)newTarget error:(NSError **)error;

/**
 * Updates the on-disk reference to the name and returns the renamed reference.
 *
 * Note that this does *not* change the receiver's name.
 *
 * @param newName	The new name for the reference. Cannot be nil.
 * @param error		The error if one occurred.
 *
 * @return Returns the renamed reference, or nil if an error occurred.
 */
- (GTReference *)referenceByRenaming:(NSString *)newName error:(NSError **)error;

/**
 * Delete this reference.
 *
 * @param error The error if one occurred.
 *
 * @return Returns whether the deletion was successful.
 */
- (BOOL)deleteWithError:(NSError **)error;

/**
 * Resolve this reference as a symbolic ref
 *
 * @param error will be filled if an error occurs
 *
 * @return returns the peeled GTReference or nil if an error occurred.
 */
- (GTReference *)resolvedReferenceWithError:(NSError **)error;

/**
 * Reload the reference from disk.
 *
 * @param error The error if one occurred.
 *
 * @return Returns the reloaded reference, or nil if an error occurred.
 */
- (GTReference *)reloadedReferenceWithError:(NSError **)error;

/// An error indicating that the git_reference is no longer valid.
+ (NSError *)invalidReferenceError;

@end
