//
//  GTDiffLine.m
//  ObjectiveGitFramework
//
//  Created by Danny Greg on 20/12/2012.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "GTDiffLine.h"

@implementation GTDiffLine

- (instancetype)initWithGitLine:(const git_diff_line *)line {
	self = [super init];
	if (self == nil) return nil;

	NSData *lineData = [[NSData alloc] initWithBytesNoCopy:(void *)line->content length:line->content_len freeWhenDone:NO];

	NSArray *encodings = @[
		@(NSUTF8StringEncoding),
		@(NSISOLatin1StringEncoding),
		@(NSISOLatin2StringEncoding),
		@(NSWindowsCP1252StringEncoding),
		@(NSMacOSRomanStringEncoding),
	];

	__block NSString *string;

	[encodings enumerateObjectsUsingBlock:^(NSNumber *encoding, NSUInteger idx, BOOL *stop) {
		string = [[NSString alloc] initWithData:lineData encoding:encoding.unsignedIntegerValue];

		// Try the next encoding
		if (string == nil) return;

		// If this string is already UTF8 we're done.
		if (encoding.unsignedIntegerValue == NSUTF8StringEncoding) *stop = YES;

		// Check we can convert it to UTF8
		NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

		if (string != nil) *stop = YES;
	}];

	_content = [string stringByTrimmingCharactersInSet:NSCharacterSet.newlineCharacterSet];
	_oldLineNumber = line->old_lineno;
	_newLineNumber = line->new_lineno;
	_origin = line->origin;
	_lineCount = line->num_lines;
	
	return self;
}

- (NSString *)debugDescription {
	return [NSString stringWithFormat:@"%@ origin: %u, lines: %ld, oldLineNumber: %ld, newLineNumber: %ld, content: %@", super.debugDescription, self.origin, (long)self.lineCount, (long)self.oldLineNumber, (long)self.newLineNumber, self.content];
}

@end
