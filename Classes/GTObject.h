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
#import "GTRepository.h"

/*typedef enum {
	Commit = 1,
	Tree = 2,
	Blob = 3,
	Tag = 4
} GTObjectType;*/

@interface GTObject : NSObject {}

@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, copy, readonly) NSString *sha;
@property (nonatomic, assign) git_object *object;
@property (nonatomic, retain) GTRepository *repo;

+ (git_object *)getNewObjectInRepo:(git_repository *)r type:(git_otype)theType error:(NSError **)error;
+ (git_object *)getNewObjectInRepo:(git_repository *)r sha:(NSString *)sha type:(git_otype)theType error:(NSError **)error;

+ (id)objectInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject; 
- (id)initInRepo:(GTRepository *)theRepo withObject:(git_object *)theObject;
- (NSString *)writeAndReturnError:(NSError **)error;
- (GTRawObject *)readRawAndReturnError:(NSError **)error;

@end

