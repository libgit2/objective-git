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

#include "git2.h"

typedef enum {
	GTObjectTypeAny = GIT_OBJ_ANY,				/**< Object can be any of the following */
	GTObjectTypeBad = GIT_OBJ_BAD,				/**< Object is invalid. */
	GTObjectTypeExt1 = GIT_OBJ__EXT1,			/**< Reserved for future use. */
	GTObjectTypeCommit = GIT_OBJ_COMMIT,		/**< A commit object. */
	GTObjectTypeTree = GIT_OBJ_TREE,			/**< A tree (directory listing) object. */
	GTObjectTypeBlob = GIT_OBJ_BLOB,			/**< A file revision object. */
	GTObjectTypeTag = GIT_OBJ_TAG,				/**< An annotated tag object. */
	GTObjectTypeExt2 = GIT_OBJ__EXT2,			/**< Reserved for future use. */
	GTObjectTypeOffsetDelta = GIT_OBJ_OFS_DELTA,/**< A delta, base is given by an offset. */
	GTObjectTypeRefDelta = GIT_OBJ_REF_DELTA,	/**< A delta, base is given by object id. */
} GTObjectType;

@class GTRepository;
@class GTOdbObject;
@class GTOID;

@interface GTObject : NSObject

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *SHA;
@property (nonatomic, readonly) NSString *shortSHA;
@property (nonatomic, readonly, strong) GTRepository *repository;
@property (nonatomic, readonly) GTOID *OID;

// Convenience initializers
- (id)initWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo;
+ (id)objectWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo;

// The underlying `git_object`.
- (git_object *)git_object __attribute__((objc_returns_inner_pointer));

// Read the raw object from the datastore
//
// error(out) - will be filled if an error occurs
// 
// returns a GTOdbObject or nil if an error occurred.
- (GTOdbObject *)odbObjectWithError:(NSError **)error;

// Recursively peel an object until an object of the specified type is met.
//
// type  - The type of the requested object. If you pass GTObjectTypeAny
//         the object will be peeled until the type changes (e.g. a tag will
//         be chased until the referenced object is no longer a tag).
// error - Will be filled with a NSError object on failure.
//         May be NULL.
//
// Returns the found object or nil on error.
- (id)objectByPeelingToType:(GTObjectType)type error:(NSError **)error;

@end

