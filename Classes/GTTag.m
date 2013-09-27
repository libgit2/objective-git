//
//  GTTag.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
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

#import "GTTag.h"
#import "NSError+Git.h"
#import "GTSignature.h"
#import "GTReference.h"
#import "GTRepository.h"
#import "NSString+Git.h"
#import "GTOID.h"

@implementation GTTag

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> name: %@, message: %@, targetType: %d", NSStringFromClass([self class]), self,self.name, self.message, self.targetType];
}

#pragma mark API

- (NSString *)message {
	return @(git_tag_message(self.git_tag));
}

- (NSString *)name {
	return @(git_tag_name(self.git_tag));
}

- (GTObject *)target {
	git_object *t;
	int gitError = git_tag_target(&t, self.git_tag);
	if (gitError < GIT_OK) return nil;
	return [GTObject objectWithObj:(git_object *)t inRepository:self.repository];
}

- (GTObjectType)targetType {
	return (GTObjectType)git_tag_target_type(self.git_tag);
}

- (GTSignature *)tagger {
	return [[GTSignature alloc] initWithGitSignature:git_tag_tagger(self.git_tag)];
}

- (git_tag *)git_tag {
	return (git_tag *) self.git_object;
}

- (id)objectByPeelingTagError:(NSError **)error {
	git_object *target = nil;
	int gitError = git_tag_peel(&target, self.git_tag);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Cannot peel tag"];
		return nil;
	}

	return [[GTObject alloc] initWithObj:target inRepository:self.repository];
}

@end
