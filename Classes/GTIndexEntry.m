//
//  GTIndexEntry.m
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

#import "GTIndexEntry.h"
#import "GTLib.h"
#import "NSString+Git.h"
#import "NSError+Git.h"


@implementation GTIndexEntry

- (void)dealloc {
	
	// todo: do we free here?
	// free(self.entry);
	[super dealloc];
}

#pragma mark -
#pragma mark API

@synthesize entry;
@synthesize path;
@synthesize modificationDate;
@synthesize creationDate;
@synthesize fileSize;
@synthesize dev;
@synthesize ino;
@synthesize mode;
@synthesize uid;
@synthesize gid;
@synthesize flags;
@synthesize stage;
@synthesize isValid;

- (id)init {
	
	if((self = [super init])) {
		self.entry = malloc(sizeof(git_index_entry));
		memset(self.entry, 0x0, sizeof(git_index_entry));
	}
	return self;
}

- (id)initWithEntry:(git_index_entry *)theEntry {
	
	if((self = [super init])) {
		self.entry = theEntry;
	}
	return self;
}
+ (id)indexEntryWithEntry:(git_index_entry *)theEntry {
	
	return [[[self alloc] initWithEntry:theEntry] autorelease];
}

- (NSString *)path {
	
	if(self.entry->path == NULL)return nil;
	return [NSString stringForUTF8String:self.entry->path];
}
- (void)setPath:(NSString *)thePath {
	
	if(self.entry->path != NULL)
		free(self.entry->path);
	
	entry->path = strdup([NSString utf8StringForString:thePath]);
}

- (NSString *)sha {
	
	return [GTLib convertOidToSha:&entry->oid];
}
- (BOOL)setSha:(NSString *)theSha error:(NSError **)error {

	int gitError = git_oid_mkstr(&entry->oid, [NSString utf8StringForString:theSha]);
	if(gitError != GIT_SUCCESS) {
		if(error != NULL)
			*error = [NSError gitErrorForMkStr:gitError];
		return NO;
	}
	return YES;
}

- (NSDate *)modificationDate {
	
	double time = self.entry->mtime.seconds + (self.entry->mtime.nanoseconds/1000);
	return [NSDate dateWithTimeIntervalSince1970:time];
}
- (void)setModificationDate:(NSDate *)time {
	
	NSTimeInterval t = [time timeIntervalSince1970];
	self.entry->mtime.seconds = (int)t;
	self.entry->mtime.nanoseconds = 1000 * (t - (int)t);
}

- (NSDate *)creationDate {
	
	double time = self.entry->ctime.seconds + (self.entry->ctime.nanoseconds/1000);
	return [NSDate dateWithTimeIntervalSince1970:time];
}
- (void)setCreationDate:(NSDate *)time {
	
	NSTimeInterval t = [time timeIntervalSince1970];
	self.entry->ctime.seconds = (int)t;
	self.entry->ctime.nanoseconds = 1000 * (t - (int)t);
}

- (long long)fileSize { return self.entry->file_size; }
- (void)setFileSize:(long long) size { self.entry->file_size = size; }

- (NSUInteger)dev { return self.entry->dev; }
- (void)setDev:(NSUInteger)theDev { self.entry->dev = theDev; }

- (NSUInteger)ino { return self.entry->ino; }
- (void)setIno:(NSUInteger)theIno { self.entry->ino = theIno; }

- (NSUInteger)mode { return self.entry->mode; }
- (void)setMode:(NSUInteger)theMode { self.entry->mode = theMode; }

- (NSUInteger)uid { return self.entry->uid; }
- (void)setUid:(NSUInteger)theUid { self.entry->uid = theUid; }

- (NSUInteger)gid { return self.entry->gid; }
- (void)setGid:(NSUInteger)theGid { self.entry->gid = theGid; }

- (NSUInteger)flags {
	
	return (self.entry->flags & 0xFFFF) | (self.entry->flags_extended << 16); 
}
- (void)setFlags:(NSUInteger)theFlags {
	
	self.entry->flags = (unsigned short)(theFlags & 0xFFFF);
	self.entry->flags_extended = (unsigned short)((theFlags >> 16) & 0xFFFF);
}

- (BOOL)isValid {
	
	return (self.flags & GIT_IDXENTRY_VALID) != 0;
}

- (NSUInteger)stage {
	
	return (self.entry->flags & GIT_IDXENTRY_STAGEMASK) >> GIT_IDXENTRY_STAGESHIFT;
}
- (void)setStage:(NSUInteger)theStage {
	
	NSParameterAssert(theStage >= 0 && theStage <= 3);
	
	self.entry->flags &= ~GIT_IDXENTRY_STAGEMASK;
	self.entry->flags |= (theStage << GIT_IDXENTRY_STAGESHIFT);
}

@end
