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
typedef enum : git_diff_line_t {
	GTDiffLineOriginContext = GIT_DIFF_LINE_CONTEXT,
	GTDiffLineOriginAddition = GIT_DIFF_LINE_ADDITION,
	GTDiffLineOriginDeletion = GIT_DIFF_LINE_DELETION,
	GTDiffLineOriginAddEOFNewLine = GIT_DIFF_LINE_ADD_EOFNL,
	GTDiffLineOriginDeleteEOFNewLine = GIT_DIFF_LINE_DEL_EOFNL,
} GTDiffLineOrigin;

// Represents an individual line in a diff hunk.
@interface GTDiffLine : NSObject

// The content string of the line.
@property (nonatomic, readonly, copy) NSString *content;

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

// Designated initialiser.
- (instancetype)initWithContent:(NSString *)content oldLineNumber:(NSInteger)oldLineNumber newLineNumber:(NSInteger)newLineNumber origin:(GTDiffLineOrigin)origin;

@end
