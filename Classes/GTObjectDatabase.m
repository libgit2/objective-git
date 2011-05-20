//
//  GTObjectDatabase.m
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

#import "GTObjectDatabase.h"
#import "GTRepository.h"
#import "NSError+Git.h"
#import "GTOdbObject.h"
#import "GTLib.h"

@interface GTObjectDatabase ()
@property (nonatomic, assign) GTRepository *repository;
@end

@implementation GTObjectDatabase

- (void)dealloc {
    self.repository = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark API

@synthesize repository;

+ (id)objectDatabaseWithRepository:(GTRepository *)repo {
    return [[[self alloc] initWithRepository:repo] autorelease];
}

- (id)initWithRepository:(GTRepository *)repo {
    self = [super init];
    if (self) {
        self.repository = repo;
        odb = git_repository_database(self.repository.repo);
    }
    return self;
}

- (GTOdbObject *)objectWithOid:(const git_oid *)oid error:(NSError **)error {
	git_odb_object *obj;
	
	int gitError = git_odb_read(&obj, odb, oid);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForRawRead:gitError];
		return nil;
	}
	
	GTOdbObject *rawObj = [GTOdbObject objectWithOdbObj:obj];
	git_odb_object_close(obj);
	
	return rawObj;    
}

- (GTOdbObject *)objectWithSha:(NSString *)sha error:(NSError **)error {
	git_oid oid;
	int gitError = git_oid_mkstr(&oid, [sha UTF8String]);
	if(gitError != GIT_SUCCESS) {
		if (error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return nil;
	}
    return [self objectWithOid:&oid error:error];
}

- (NSString *)shaByInsertingString:(NSString *)data objectType:(GTObjectType)type error:(NSError **)error {
	
	git_odb_stream *stream;
	git_oid oid;
	
	int gitError = git_odb_open_wstream(&stream, odb, data.length, type);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to open write stream on odb"];
		return nil;
	}
	
	gitError = stream->write(stream, [data UTF8String], data.length);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to write to stream on odb"];
		return nil;
	}
	
	gitError = stream->finalize_write(&oid, stream);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorFor:gitError withDescription:@"Failed to finalize write on odb"];
		return nil;
	}
    
	return [GTLib convertOidToSha:&oid];
}

- (BOOL)containsObjectWithSha:(NSString *)sha error:(NSError **)error {
	
	git_oid oid;
	
	int gitError = git_oid_mkstr(&oid, [sha UTF8String]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return NO;
	}
	
	return git_odb_exists(odb, &oid) ? YES : NO;
}

@end