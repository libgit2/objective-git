//
//  GTTag.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/28/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTTag.h"
#import "NSString+Git.h"
#import "GTSignature.h"

@implementation GTTag

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
	
	return [GTObject objectInRepo:self.repo withObject:(git_object *)git_tag_target(self.tag)];
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
