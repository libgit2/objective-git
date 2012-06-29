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
#import "NSError+Git.h"
#import "NSString+Git.h"


@implementation GTIndexEntry

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> path: %@, modificationDate: %@, creationDate: %@, fileSize: %lld KB, flags: %lu", NSStringFromClass([self class]), self, self.path, self.modificationDate, self.creationDate, self.fileSize, (unsigned long)self.flags];
}

- (void)dealloc {
	free(self.git_index_entry);
}


#pragma mark API

@synthesize git_index_entry;
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
@synthesize staged;
@synthesize valid;
@synthesize repository;

+ (id)indexEntryWithEntry:(git_index_entry *)theEntry {
	if (theEntry == NULL)
		return nil;

	return [[self alloc] initWithEntry:theEntry];
}

- (id)init {
	if((self = [super init])) {
		self.git_index_entry = calloc(1, sizeof(git_index_entry));
	}
	return self;
}

- (id)initWithEntry:(git_index_entry *)theEntry {
	if((self = [self init])) {
		if (theEntry)
		{
			git_index_entry *thisEntry = self.git_index_entry;
			memcpy(thisEntry, theEntry, sizeof(git_index_entry));
		}
	}
	return self;
}

- (NSString *)path {
	if(self.git_index_entry->path == NULL) return nil;
	return [NSString stringWithUTF8String:self.git_index_entry->path];
}

- (void)setPath:(NSString *)thePath {
	if(self.git_index_entry->path != NULL)
		free((void *)self.git_index_entry->path);
	
	self.git_index_entry->path = strdup([thePath UTF8String]);
}

- (NSString *)sha {
	return [NSString git_stringWithOid:&git_index_entry->oid];
}

- (BOOL)setSha:(NSString *)theSha error:(NSError **)error {
	int gitError = git_oid_fromstr(&git_index_entry->oid, [theSha UTF8String]);
	if(gitError < GIT_OK) {
		if(error != NULL)
			*error = [NSError git_errorForMkStr:gitError];
		return NO;
	}
	return YES;
}

- (NSDate *)modificationDate {	
	double time = self.git_index_entry->mtime.seconds + (self.git_index_entry->mtime.nanoseconds/1000);
	return [NSDate dateWithTimeIntervalSince1970:time];
}

- (void)setModificationDate:(NSDate *)time {
	NSTimeInterval t = [time timeIntervalSince1970];
	self.git_index_entry->mtime.seconds = (int)t;
	self.git_index_entry->mtime.nanoseconds = (unsigned int) (1000 * (t - (int)t));
}

- (NSDate *)creationDate {
	double time = self.git_index_entry->ctime.seconds + (self.git_index_entry->ctime.nanoseconds/1000);
	return [NSDate dateWithTimeIntervalSince1970:time];
}

- (void)setCreationDate:(NSDate *)time {	
	NSTimeInterval t = [time timeIntervalSince1970];
	self.git_index_entry->ctime.seconds = (int)t;
	self.git_index_entry->ctime.nanoseconds = (unsigned int) (1000 * (t - (int)t));
}

- (long long)fileSize { return self.git_index_entry->file_size; }
- (void)setFileSize:(long long) size { self.git_index_entry->file_size = (git_off_t)size; }

- (NSUInteger)dev { return self.git_index_entry->dev; }
- (void)setDev:(NSUInteger)theDev { self.git_index_entry->dev = (unsigned int)theDev; }

- (NSUInteger)ino { return self.git_index_entry->ino; }
- (void)setIno:(NSUInteger)theIno { self.git_index_entry->ino = (unsigned int)theIno; }

- (NSUInteger)mode { return self.git_index_entry->mode; }
- (void)setMode:(NSUInteger)theMode { self.git_index_entry->mode = (unsigned int)theMode; }

- (NSUInteger)uid { return self.git_index_entry->uid; }
- (void)setUid:(NSUInteger)theUid { self.git_index_entry->uid = (unsigned int)theUid; }

- (NSUInteger)gid { return self.git_index_entry->gid; }
- (void)setGid:(NSUInteger)theGid { self.git_index_entry->gid = (unsigned int)theGid; }

- (NSUInteger)flags {
	return (NSUInteger) ((self.git_index_entry->flags & 0xFFFF) | (self.git_index_entry->flags_extended << 16));
}

- (void)setFlags:(NSUInteger)theFlags {	
	self.git_index_entry->flags = (unsigned short)(theFlags & 0xFFFF);
	self.git_index_entry->flags_extended = (unsigned short)((theFlags >> 16) & 0xFFFF);
}

- (BOOL)isValid {
	return (self.flags & GIT_IDXENTRY_VALID) != 0;
}

- (NSUInteger)isStaged {
	return (self.git_index_entry->flags & GIT_IDXENTRY_STAGEMASK) >> GIT_IDXENTRY_STAGESHIFT;
}

- (GTIndexEntryStatus)status {
	if((self.flags & GIT_IDXENTRY_UPDATE) != 0) {
		return GTIndexEntryStatusUpdated;
	} else if((self.flags & GIT_IDXENTRY_UPTODATE) != 0) {
		return GTIndexEntryStatusUnchanged;
	}
	
	return GTIndexEntryStatusUnchanged;
}

@end
