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
#import "NSString+Git.h"
#import "GTSignature.h"


@implementation GTTag

- (void)dealloc {
	
	// All these properties pass through to underlying C object
	// there is nothing to release here
	//self.message = nil;
	//self.name = nil;
	//self.target = nil;
	//self.targetType = nil;
	//self.tagger = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark API

@synthesize tag;
@synthesize message;
@synthesize name;
@synthesize target;
@synthesize targetType;
@synthesize tagger;

- (git_tag *)tag {
	
	return (git_tag *)self.object;
}

- (NSString *)message {
	
	return [NSString stringForUTF8String:git_tag_message(self.tag)];
}
- (void)setMessage:(NSString *)theMessage {
	
	git_tag_set_message(self.tag, [NSString utf8StringForString:theMessage]);
}

- (NSString *)name {
	
	return [NSString stringForUTF8String:git_tag_name(self.tag)];
}
- (void)setName:(NSString *)theName {
	
	git_tag_set_name(self.tag, [NSString utf8StringForString:theName]);
}

- (GTObject *)target {
	
	git_object *t;
	// todo: might want to actually return an error here
	int gitError = git_tag_target(&t, self.tag);
	if(gitError != GIT_SUCCESS) return nil;
	return [GTObject objectInRepo:self.repo withObject:(git_object *)t];
}
- (void)setTarget:(GTObject *)theTarget {
	
	git_tag_set_target(self.tag, theTarget.object);
}

- (NSString *)targetType {
	
	return [NSString stringForUTF8String:git_object_type2string(git_tag_type(self.tag))];
}

- (GTSignature *)tagger {
	
	return [GTSignature signatureWithSignature:(git_signature *)git_tag_tagger(self.tag)];
}
- (void)setTagger:(GTSignature *)theTagger {
	
	git_tag_set_tagger(self.tag, theTagger.signature);
}

@end
