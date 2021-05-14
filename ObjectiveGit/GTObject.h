//
//  GTObject.h
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/22/11.
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

#import <Foundation/Foundation.h>
#import <ObjectiveGit/git2/types.h>

typedef NS_ENUM(int, GTObjectType) {
	GTObjectTypeAny = GIT_OBJECT_ANY,				/**< Object can be any of the following */
	GTObjectTypeBad = GIT_OBJECT_INVALID,				/**< Object is invalid. */
	GTObjectTypeCommit = GIT_OBJECT_COMMIT,		/**< A commit object. */
	GTObjectTypeTree = GIT_OBJECT_TREE,			/**< A tree (directory listing) object. */
	GTObjectTypeBlob = GIT_OBJECT_BLOB,			/**< A file revision object. */
	GTObjectTypeTag = GIT_OBJECT_TAG,				/**< An annotated tag object. */
	GTObjectTypeOffsetDelta = GIT_OBJECT_OFS_DELTA,/**< A delta, base is given by an offset. */
	GTObjectTypeRefDelta = GIT_OBJECT_REF_DELTA,	/**< A delta, base is given by object id. */
};

@class GTRepository;
@class GTOdbObject;
@class GTOID;

NS_ASSUME_NONNULL_BEGIN

@interface GTObject : NSObject

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *SHA;
@property (nonatomic, readonly) NSString *shortSHA;
@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly) GTOID *OID;

- (instancetype)init NS_UNAVAILABLE;

/// Designated initializer.
- (id _Nullable)initWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo NS_DESIGNATED_INITIALIZER;

/// Class convenience initializer
+ (id _Nullable)objectWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo;

/// The underlying `git_object`.
- (git_object *)git_object __attribute__((objc_returns_inner_pointer));

/// Read the raw object from the datastore
///
/// error(out) - will be filled if an error occurs
///
/// returns a GTOdbObject or nil if an error occurred.
- (GTOdbObject * _Nullable)odbObjectWithError:(NSError * __autoreleasing *)error;

/// Recursively peel an object until an object of the specified type is met.
///
/// type  - The type of the requested object. If you pass GTObjectTypeAny
///         the object will be peeled until the type changes (e.g. a tag will
///         be chased until the referenced object is no longer a tag).
/// error - Will be filled with a NSError object on failure.
///         May be NULL.
///
/// Returns the found object or nil on error.
- (id _Nullable)objectByPeelingToType:(GTObjectType)type error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END
