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

#import <git2.h>


typedef enum {
	GTObjectTypeAny = -2,			/**< Object can be any of the following */
	GTObjectTypeBad = -1,			/**< Object is invalid. */
	GTObjectTypeExt1 = 0,			/**< Reserved for future use. */
	GTObjectTypeCommit = 1,		/**< A commit object. */
	GTObjectTypeTree = 2,			/**< A tree (directory listing) object. */
	GTObjectTypeBlob = 3,			/**< A file revision object. */
	GTObjectTypeTag = 4,			/**< An annotated tag object. */
	GTObjectTypeExt2 = 5,			/**< Reserved for future use. */
	GTObjectTypeOffsetDelta = 6,	/**< A delta, base is given by an offset. */
	GTObjectTypeRefDelta = 7,		/**< A delta, base is given by object id. */
} GTObjectType;

@class GTRepository;
@class GTRawObject;

@interface GTObject : NSObject {}

@property (nonatomic, assign) git_object *object;
@property (nonatomic, assign, readonly) NSString *type;
@property (nonatomic, assign, readonly) NSString *sha;
@property (nonatomic, assign) GTRepository *repo;

// Convenience initializers
- (id)initInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject;
+ (id)objectInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject; 

// Helpers
+ (git_object *)getNewObjectInRepo:(git_repository *)r type:(GTObjectType)theType error:(NSError **)error;
+ (git_object *)getNewObjectInRepo:(git_repository *)r sha:(NSString *)sha type:(GTObjectType)theType error:(NSError **)error;

// Write this object to the datastore
//
// error(out) - will be filled if an error occurs
//
// returns an NSString of the sha1 hash of the written object or nil if an error occurred.
- (NSString *)writeAndReturnError:(NSError **)error;

// Red the raw object from the datastore
//
// error(out) - will be filled if an error occurs
// 
// returns a GTRawObject or nil if an error occurred.
- (GTRawObject *)readRawAndReturnError:(NSError **)error;

@end

