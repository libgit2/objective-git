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

@interface GTTag ()
@property (nonatomic, strong) GTSignature *tagger;
@end


@implementation GTTag

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> name: %@, message: %@, targetType: %@", NSStringFromClass([self class]), self, [self name], [self message],  [self targetType]];
}


#pragma mark API

@synthesize tagger;

+ (GTTag *)tagInRepository:(GTRepository *)theRepo name:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error {
	NSString *sha = [GTTag shaByCreatingTagInRepository:theRepo name:tagName target:theTarget tagger:theTagger message:theMessage error:error];
	return sha ? (GTTag *)[theRepo lookupObjectBySha:sha objectType:GTObjectTypeTag error:error] : nil;
}

+ (NSString *)shaByCreatingTagInRepository:(GTRepository *)theRepo name:(NSString *)tagName target:(GTObject *)theTarget tagger:(GTSignature *)theTagger message:(NSString *)theMessage error:(NSError **)error {
	git_oid oid;
	int gitError = git_tag_create(&oid, theRepo.git_repository, [tagName UTF8String], theTarget.git_object, theTagger.git_signature, [theMessage UTF8String], 0);
	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorFor:gitError withAdditionalDescription:@"Failed to create tag in repository"];
		return nil;
	}
	
	return [NSString git_stringWithOid:&oid];
}

- (NSString *)message {
	return [NSString stringWithUTF8String:git_tag_message(self.git_tag)];
}

- (NSString *)name {
	return [NSString stringWithUTF8String:git_tag_name(self.git_tag)];
}

- (GTObject *)target {
	git_object *t;
	// todo: might want to actually return an error here
	int gitError = git_tag_target(&t, self.git_tag);
	if(gitError < GIT_OK) return nil;
    return [GTObject objectWithObj:(git_object *)t inRepository:self.repository];
}

- (NSString *)targetType {
	return [NSString stringWithUTF8String:git_object_type2string(git_tag_target_type(self.git_tag))];
}

- (GTSignature *)tagger {
	if(tagger == nil) {
		tagger = [GTSignature signatureWithSignature:(git_signature *)git_tag_tagger(self.git_tag)];
	}
	return tagger;
}

- (git_tag *)git_tag {
	return (git_tag *) self.git_object;
}

@end
