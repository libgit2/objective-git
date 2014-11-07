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
#import "GTOID.h"
#import "NSString+Git.h"
#import "GTOID.h"
#import "EXTScope.h"

#import "git2/odb_backend.h"

@interface GTObjectDatabase ()
@property (nonatomic, readonly, assign) git_odb *git_odb;
@end

@implementation GTObjectDatabase

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> repository: %@", NSStringFromClass([self class]), self, self.repository];
}

- (void)dealloc {
	if (_git_odb != NULL) {
		git_odb_free(_git_odb);
		_git_odb = NULL;
	}
}

#pragma mark API

- (id)initWithRepository:(GTRepository *)repo error:(NSError **)error {
	NSParameterAssert(repo != nil);

	self = [super init];
	if (self == nil) return nil;

	_repository = repo;

	int gitError = git_repository_odb(&_git_odb, repo.git_repository);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to get ODB for repo."];
		return nil;
	}

	return self;
}

- (GTOdbObject *)objectWithOID:(GTOID *)oid error:(NSError **)error {
	git_odb_object *obj;
	int gitError = git_odb_read(&obj, self.git_odb, oid.git_oid);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to read raw object with OID %@", oid.SHA];
		return nil;
	}

	return [[GTOdbObject alloc] initWithOdbObj:obj repository:self.repository];
}

- (GTOdbObject *)objectWithSHA:(NSString *)sha error:(NSError **)error {
	GTOID *oid = [[GTOID alloc] initWithSHA:sha error:error];
	if (oid == nil) return nil;

    return [self objectWithOID:oid error:error];
}

#pragma mark Writing

- (GTOID *)writeData:(NSData *)data type:(GTObjectType)type error:(NSError **)error {
	NSParameterAssert(data != nil);

	git_odb_stream *stream;
	int gitError = git_odb_open_wstream(&stream, self.git_odb, data.length, (git_otype)type);
	@onExit {
		if (stream != NULL) git_odb_stream_free(stream);
	};

	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to open write stream on odb."];
		return nil;
	}

	gitError = git_odb_stream_write(stream, data.bytes, data.length);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to write to stream on odb."];
		return nil;
	}

	git_oid oid;
	gitError = git_odb_stream_finalize_write(&oid, stream);
	if (gitError != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:gitError description:@"Failed to finalize write on odb."];
		return nil;
	}

	return [GTOID oidWithGitOid:&oid];
}

- (BOOL)containsObjectWithSHA:(NSString *)sha error:(NSError **)error {
	GTOID *oid = [[GTOID alloc] initWithSHA:sha error:error];
	if (oid == nil) return NO;

	return [self containsObjectWithOID:oid];
}

- (BOOL)containsObjectWithOID:(GTOID *)oid {
	return git_odb_exists(self.git_odb, oid.git_oid) ? YES : NO;
}

@end
