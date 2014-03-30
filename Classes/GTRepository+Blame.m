//
//  GTRepository+Blame.m
//  ObjectiveGitFramework
//
//  Created by Ezekiel Pierson on 2/5/14.
//  Copyright (c) 2014 GitHub, Inc. All rights reserved.
//

#import "GTRepository+Blame.h"
#import "git2.h"

NSString * const GTBlameOptionsFlags = @"GTBlameOptionsFlags";
NSString * const GTBlameOptionsNewestCommitOID = @"GTBlameOptionsNewestCommitOID";
NSString * const GTBlameOptionsOldestCommitOID = @"GTBlameOptionsOldestCommitOID";
NSString * const GTBlameOptionsFirstLine = @"GTBlameOptionsFirstLine";
NSString * const GTBlameOptionsLastLine = @"GTBlameOptionsLastLine";

@implementation GTRepository (Blame)

- (GTBlame *)blameWithFile:(NSString *)path options:(NSDictionary *)options error:(NSError **)error {
	NSParameterAssert(path != nil);
	
	git_blame *blame = NULL;
	git_blame_options blame_options = GIT_BLAME_OPTIONS_INIT;
	const git_oid *newest_commit = [options[GTBlameOptionsNewestCommitOID] git_oid];
	const git_oid *oldest_commit = [options[GTBlameOptionsOldestCommitOID] git_oid];

	blame_options.flags = (uint32_t)[options[GTBlameOptionsFlags] unsignedIntegerValue];
	if (newest_commit != nil) blame_options.newest_commit = *newest_commit;
	if (oldest_commit != nil) blame_options.oldest_commit = *oldest_commit;
	blame_options.min_line = (uint32_t)[options[GTBlameOptionsFirstLine] unsignedIntegerValue];
	blame_options.max_line = (uint32_t)[options[GTBlameOptionsLastLine] unsignedIntegerValue];
	
	int returnValue = git_blame_file(&blame, self.git_repository, path.fileSystemRepresentation, &blame_options);

	if (returnValue != GIT_OK) {
		if (error != NULL) *error = [NSError git_errorFor:returnValue description:@"Failed to create blame for file %@", path];
		return nil;
	}
	
	return [[GTBlame alloc] initWithGitBlame:blame];
}

@end
