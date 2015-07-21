//
//  GTDiffLine.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 20/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "git2/diff.h"

/// A character representing the origin of a given line.
///
/// See diff.h for individual documentation.
typedef NS_ENUM(char, GTDiffLineOrigin) {
	GTDiffLineOriginContext = GIT_DIFF_LINE_CONTEXT,
	GTDiffLineOriginAddition = GIT_DIFF_LINE_ADDITION,
	GTDiffLineOriginDeletion = GIT_DIFF_LINE_DELETION,
	GTDiffLineOriginNoEOFNewlineContext = GIT_DIFF_LINE_CONTEXT_EOFNL,
	GTDiffLineOriginAddEOFNewLine = GIT_DIFF_LINE_ADD_EOFNL,
	GTDiffLineOriginDeleteEOFNewLine = GIT_DIFF_LINE_DEL_EOFNL,
};

NS_ASSUME_NONNULL_BEGIN

/// Represents an individual line in a diff hunk.
@interface GTDiffLine : NSObject

/// The content string of the line.
@property (nonatomic, readonly, copy) NSString *content;

/// The line number of this line in the left side of the diff.
///
/// -1 if the line is an addition.
@property (nonatomic, readonly) NSInteger oldLineNumber;

/// The line number of this line in the right side of the diff.
///
/// -1 if the line is a deletion.
@property (nonatomic, readonly) NSInteger newLineNumber;

/// The origin of the line, see the enum above for possible values.
@property (nonatomic, readonly) GTDiffLineOrigin origin;

/// The number of newlines appearing in `-content`.
@property (nonatomic, readonly) NSInteger lineCount;

- (instancetype)init NS_UNAVAILABLE;

/// Designated initialiser.
///
/// line - The diff line to wrap. May not be NULL.
///
/// Returns a diff line, or nil if an error occurs.
- (nullable instancetype)initWithGitLine:(const git_diff_line *)line NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
