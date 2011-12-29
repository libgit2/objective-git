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
#import "dct_weak.h"

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

@protocol GTObject <NSObject>

@required
- (GTRepository *)repository;

@end

@interface GTObject : NSObject <GTObject> {}

@property (nonatomic, readonly) git_object *git_object;
@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) NSString *sha;
@property (nonatomic, readonly) NSString *shortSha;
@property (nonatomic, dct_weak) GTRepository *repository;

// Convenience initializers
- (id)initWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo;
+ (id)objectWithObj:(git_object *)theObject inRepository:(GTRepository *)theRepo;

// Read the raw object from the datastore
//
// error(out) - will be filled if an error occurs
// 
// returns a GTOdbObject or nil if an error occurred.
- (GTOdbObject *)odbObjectWithError:(NSError **)error;

@end

