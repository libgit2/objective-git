//
//  GTObjectDatabase.h
//  ObjectiveGitFramework
//
//  Created by Dave DeLong on 5/17/2011.
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
#import "GTObject.h"


@interface GTObjectDatabase : NSObject <GTObject> {
    git_odb *odb;
}

@property (nonatomic, assign, readonly) GTRepository *repository;

+ (id)objectDatabaseWithRepository:(GTRepository *)repository;
- (id)initWithRepository:(GTRepository *)repository;

- (GTOdbObject *)objectWithOid:(const git_oid *)oid error:(NSError **)error;
- (GTOdbObject *)objectWithSha:(NSString *)sha error:(NSError **)error;

- (NSString *)shaByInsertingString:(NSString *)data objectType:(GTObjectType)type error:(NSError **)error;

- (BOOL)containsObjectWithSha:(NSString *)sha error:(NSError **)error;

@end