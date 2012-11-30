//
//  GTDiffHunk.h
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 30/11/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

typedef enum : git_diff_line_t {
	GTDiffHunkLineOriginContext = GIT_DIFF_LINE_CONTEXT,
	GTDiffHunkLineOriginAddition = GIT_DIFF_LINE_ADDITION,
	GTDiffHunkLineOriginDeletion = GIT_DIFF_LINE_DELETION,
	GTDiffHunkLineOriginAddEOFNewLine = GIT_DIFF_LINE_ADD_EOFNL,
	GTDiffHunkLineOriginDeleteEOFNewLine = GIT_DIFF_LINE_DEL_EOFNL,
} GTDiffHunkLineOrigin;

typedef BOOL(^GTDiffHunkLineProcessingBlock)(NSString *lineContent, NSUInteger oldLineNumber, NSUInteger newLineNumber, GTDiffHunkLineOrigin lineOrigin);

@interface GTDiffHunk : NSObject

@property (nonatomic, readonly, strong) NSString *header;
@property (nonatomic, readonly) NSUInteger lineCount;

- (id)initWithPatch:(git_diff_patch *)patch hunkIndex:(size_t)hunkIndex;

- (void)enumerateLinesInHunkWithBlock:(GTDiffHunkLineProcessingBlock)block;

@end
