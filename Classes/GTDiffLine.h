//
//  GTDiffLine.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 20/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

// A character representing the origin of a given line.
//
// See diff.h for individual documentation.
typedef enum {
	GTDiffLineOriginContext = GIT_DIFF_LINE_CONTEXT,
	GTDiffLineOriginAddition = GIT_DIFF_LINE_ADDITION,
	GTDiffLineOriginDeletion = GIT_DIFF_LINE_DELETION,
	GTDiffLineOriginNoEOFNewlineContext = GIT_DIFF_LINE_CONTEXT_EOFNL,
	GTDiffLineOriginAddEOFNewLine = GIT_DIFF_LINE_ADD_EOFNL,
	GTDiffLineOriginDeleteEOFNewLine = GIT_DIFF_LINE_DEL_EOFNL,
} GTDiffLineOrigin;

// Represents an individual line in a diff hunk.
@interface GTDiffLine : NSObject

// The contents of the line.
@property (nonatomic, readonly, copy) NSString *contents;

// The line number of this line in the left side of the diff.
//
// -1 if the line is an addition.
@property (nonatomic, readonly) NSInteger oldLineNumber;

// The line number of this line in the right side of the diff.
//
// -1 if the line is a deletion.
@property (nonatomic, readonly) NSInteger newLineNumber;

// The origin of the line, see the enum above for possible values.
@property (nonatomic, readonly) GTDiffLineOrigin origin;

@property (nonatomic, readonly) NSInteger numLines;

// Designated initialiser.
- (instancetype)initWithGitLine:(const git_diff_line *)line;

@end
