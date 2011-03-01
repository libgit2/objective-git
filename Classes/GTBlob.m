//
//  GTBlob.m
//  ObjectiveGitFramework
//
//  Created by Timothy Clem on 2/25/11.
//  Copyright 2011 GitHub Inc. All rights reserved.
//

#import "GTBlob.h"
#import "NSString+Git.h"


@implementation GTBlob

@synthesize size;
@synthesize content;

- (id)initInRepo:(GTRepository *)theRepo error:(NSError **)error {
	
	if(self = [super init]) {
		self.repo = theRepo;
		self.object = [GTObject getNewObjectInRepo:self.repo.repo type:GIT_OBJ_BLOB error:error];
		if(self.object == nil)return nil;
	}
	return self;
}

- (git_blob *)blob {
	
	return (git_blob *)self.object;
}

- (NSInteger)size {
	
	return git_blob_rawsize(self.blob);
}

- (NSString *)content {
	
	NSInteger s = [self size];
	if(s == 0) return [NSString stringForUTF8String:""];
	
	return [NSString stringForUTF8String:git_blob_rawcontent(self.blob)];
}
- (void)setContent:(NSString *)newContent {
		
	git_blob_set_rawcontent(self.blob, [NSString utf8StringForString:newContent], [newContent length]);
}

@end
