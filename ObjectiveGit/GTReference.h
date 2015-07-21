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
#import "git2/oid.h"

@class GTOID;
@class GTReflog;

typedef NS_ENUM(NSInteger, GTReferenceErrorCode) {
	GTReferenceErrorCodeInvalidReference = -4,
};

typedef NS_OPTIONS(NSInteger, GTReferenceType) {
	GTReferenceTypeInvalid =    GIT_REF_INVALID,  /** Invalid reference */
	GTReferenceTypeOid =        GIT_REF_OID,      /** A reference which points at an object id */
	GTReferenceTypeSymbolic =   GIT_REF_SYMBOLIC, /** A reference which points at another reference */
};

NS_ASSUME_NONNULL_BEGIN

@class GTRepository;

/// A git reference object
///
/// References are considered to be equivalent iff both their `name` and
/// `unresolvedTarget` are equal.
@interface GTReference : NSObject

@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly) GTReferenceType referenceType;
@property (nonatomic, readonly) const git_oid *git_oid;
@property (nonatomic, strong, readonly) GTOID *OID;

/// Whether this is a remote-tracking branch.
@property (nonatomic, readonly, getter = isRemote) BOOL remote;

/// The reflog for the reference.
@property (nonatomic, readonly, strong) GTReflog *reflog;

/// Convenience initializers
+ (nullable instancetype)referenceByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error;
- (nullable instancetype)initByResolvingSymbolicReference:(GTReference *)symbolicRef error:(NSError **)error;

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer.
///
/// ref        - The reference to wrap. Must not be nil.
/// repository - The repository containing the reference. Must not be nil.
///
/// Returns the initialized receiver.
- (nullable instancetype)initWithGitReference:(git_reference *)ref repository:(GTRepository *)repository NS_DESIGNATED_INITIALIZER;

/// The underlying `git_reference` object.
- (git_reference *)git_reference __attribute__((objc_returns_inner_pointer));

/// The target (either GTObject or GTReference) to which the reference points.
@property (nonatomic, readonly, copy) id unresolvedTarget;

/// The resolved object to which the reference points.
@property (nonatomic, readonly, copy) id resolvedTarget;

/// The last direct reference in a chain
@property (nonatomic, readonly, copy) GTReference *resolvedReference;

/// The OID of the target object.
@property (nonatomic, readonly, copy) GTOID *targetOID;

/// Updates the on-disk reference to point to the target and returns the updated
/// reference.
///
/// Note that this does *not* change the receiver's target.
///
/// newTarget - The target for the new reference. This must not be nil.
/// message   - A message to use when creating the reflog entry for this action.
///             This may be nil.
/// error     - The error if one occurred.
///
/// Returns the updated reference, or nil if an error occurred.
- (nullable GTReference *)referenceByUpdatingTarget:(NSString *)newTarget message:(nullable NSString *)message error:(NSError **)error;

/// The name of the reference.
@property (nonatomic, readonly, copy, nullable) NSString *name;

/// Updates the on-disk reference to the name and returns the renamed reference.
///
/// Note that this does *not* change the receiver's name.
///
/// newName - The new name for the reference. Cannot be nil.
/// error   - The error if one occurred.
///
/// Returns the renamed reference, or nil if an error occurred.
- (nullable GTReference *)referenceByRenaming:(NSString *)newName error:(NSError **)error;

/// Delete this reference.
///
/// error - The error if one occurred.
///
/// Returns whether the deletion was successful.
- (BOOL)deleteWithError:(NSError **)error;

/// Resolve this reference as a symbolic ref
///
/// error(out) - will be filled if an error occurs
///
/// returns the peeled GTReference or nil if an error occurred.
- (nullable GTReference *)resolvedReferenceWithError:(NSError **)error;

/// Reload the reference from disk.
///
/// error - The error if one occurred.
///
/// Returns the reloaded reference, or nil if an error occurred.
- (nullable GTReference *)reloadedReferenceWithError:(NSError **)error;

/// An error indicating that the git_reference is no longer valid.
+ (NSError *)invalidReferenceError;

/// Checks if a reference name is acceptable.
///
/// refName - The name to be checked.
///
/// Returns YES if the name is valid or NO otherwise.
+ (BOOL)isValidReferenceName:(NSString *)refName;

@end

NS_ASSUME_NONNULL_END
