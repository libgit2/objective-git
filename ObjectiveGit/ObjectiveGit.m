//
//  ObjectiveGit.m
//  ObjectiveGitFramework
//
//  Created by Josh Abernathy on 6/1/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "git2.h"

__attribute__((constructor))
static void GTSetupThreads(void) {
	git_threads_init();
}
