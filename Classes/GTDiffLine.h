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

@interface GTDiffLine : NSObject

@property (nonatomic, readonly) NSString *content;
@property (nonatomic, readonly) NSUInteger oldLineNumber;
@property (nonatomic, readonly) GTDiffLineOrigin origin;

- (instancetype)initWithContent:(NSString *)content oldLineNumber:(NSUInteger)oldLineNumber origin:(GTDiffLineOrigin)origin;

@end
