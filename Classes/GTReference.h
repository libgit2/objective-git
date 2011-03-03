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

#import <git2.h>

@class GTRepository;

@interface GTReference : NSObject {}

@property (nonatomic, assign) git_reference *ref;
@property (nonatomic, assign) GTRepository *repo;
@property (nonatomic, assign) NSString *name;
@property (nonatomic, assign, readonly) NSString *type;
@property (nonatomic, readonly) const git_oid *oid;

+ (id)referenceByLookingUpRef:(NSString *)refName inRepo:(GTRepository *)theRepo error:(NSError **)error;
+ (id)referenceByCreatingRef:(NSString *)refName fromRef:(NSString *)target inRepo:(GTRepository *)theRepo error:(NSError **)error;
- (id)initByLookingUpRef:(NSString *)refName inRepo:(GTRepository *)theRepo error:(NSError **)error;
- (id)initByCreatingRef:(NSString *)refName fromRef:(NSString *)target inRepo:(GTRepository *)theRepo error:(NSError **)error;

- (NSString *)target;
- (void)setTarget:(NSString *)newTarget error:(NSError **)error;
- (void)packAllAndReturnError:(NSError **)error;
- (void)deleteAndReturnError:(NSError **)error;

@end
