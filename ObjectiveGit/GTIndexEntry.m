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

@interface GTIndexEntry ()
@property (nonatomic, assign, readonly) const git_index_entry *git_index_entry;
@end

@implementation GTIndexEntry

#pragma mark NSObject

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p> path: %@", self.class, self, self.path];
}

#pragma mark Lifecycle

- (id)initWithGitIndexEntry:(const git_index_entry *)entry {
	NSParameterAssert(entry != NULL);

	self = [super init];
	if (self == nil) return nil;

	_git_index_entry = entry;
	
	return self;
}

#pragma mark Properties

- (NSString *)path {
	return @(self.git_index_entry->path);
}

- (int)flags {
	return (self.git_index_entry->flags & 0xFFFF) | (self.git_index_entry->flags_extended << 16);
}

- (BOOL)isStaged {
	return (self.git_index_entry->flags & GIT_IDXENTRY_STAGEMASK) >> GIT_IDXENTRY_STAGESHIFT;
}

- (GTIndexEntryStatus)status {
	if ((self.flags & GIT_IDXENTRY_UPDATE) != 0) {
		return GTIndexEntryStatusUpdated;
	} else if ((self.flags & GIT_IDXENTRY_UPTODATE) != 0) {
		return GTIndexEntryStatusUpToDate;
	} else if ((self.flags & GIT_IDXENTRY_CONFLICTED) != 0) {
		return GTIndexEntryStatusConflicted;
	} else if ((self.flags & GIT_IDXENTRY_ADDED) != 0) {
		return GTIndexEntryStatusAdded;
	} else if ((self.flags & GIT_IDXENTRY_REMOVE) != 0) {
		return GTIndexEntryStatusRemoved;
	}
	
	return GTIndexEntryStatusUpToDate;
}

@end
